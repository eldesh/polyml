/*
    Title:  exporter.cpp - Export a function as an object or C file

    Copyright (c) 2006-7, 2015 David C.J. Matthews

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License version 2.1 as published by the Free Software Foundation.
    
    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.
    
    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

*/

#ifdef HAVE_CONFIG_H
#include "config.h"
#elif defined(_WIN32)
#include "winconfig.h"
#else
#error "No configuration file"
#endif

#ifdef HAVE_ASSERT_H
#include <assert.h>
#define ASSERT(x) assert(x)

#else
#define ASSERT(x)
#endif

#ifdef HAVE_STRING_H
#include <string.h>
#endif

#ifdef HAVE_ERRNO_H
#include <errno.h>
#endif

#ifdef HAVE_SYS_PARAM_H
#include <sys/param.h>
#endif

#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef HAVE_TCHAR_H
#include <tchar.h>
#else
#define _T(x) x
#define _tcslen strlen
#define _tcscmp strcmp
#define _tcscat strcat
#endif

#include "exporter.h"
#include "save_vec.h"
#include "polystring.h"
#include "run_time.h"
#include "osmem.h"
#include "scanaddrs.h"
#include "gc.h"
#include "machine_dep.h"
#include "diagnostics.h"
#include "memmgr.h"
#include "processes.h" // For IO_SPACING
#include "sys.h" // For EXC_Fail

#include "pexport.h"

#ifdef HAVE_PECOFF
#include "pecoffexport.h"
#elif defined(HAVE_ELF_H) || defined(HAVE_ELF_ABI_H)
#include "elfexport.h"
#elif defined(HAVE_MACH_O_RELOC_H)
#include "machoexport.h"
#endif

#if(!defined(MAXPATHLEN) && defined(MAX_PATH))
#define MAXPATHLEN MAX_PATH
#endif

/*
To export the function and everything reachable from it we need to copy
all the objects into a new area.  We leave tombstones in the original
objects by overwriting the length word.  That prevents us from copying an
object twice and breaks loops.  Once we've copied the objects we then
have to go back over the memory and turn the tombstones back into length
words.
*/

GraveYard::~GraveYard()
{
    free(graves);
}

CopyScan::CopyScan(unsigned h/*=0*/): hierarchy(h)
{
    defaultImmSize = defaultMutSize = 0;
    defaultNoOverSize = 4096; // This can be small.
    tombs = 0;
    graveYard = 0;
}

void CopyScan::initialise(bool isExport/*=true*/)
{
    ASSERT(gMem.neSpaces == 0);
    // Set the space sizes to a proportion of the space currently in use.
    // Computing these sizes is not obvious because CopyScan is used both
    // for export and for saved states.  For saved states in particular we
    // want to use a smaller size because they are retained after we save
    // the state and if we have many child saved states it's important not
    // to waste memory.
    if (hierarchy == 0)
    {
        graveYard = new GraveYard[gMem.npSpaces];
        if (graveYard == 0)
            throw MemoryException();
    }
    unsigned i;
    for (i = 0; i < gMem.npSpaces; i++)
    {
        PermanentMemSpace *space = gMem.pSpaces[i];
        if (space->hierarchy >= hierarchy) {
            // Include this if we're exporting (hierarchy=0) or if we're saving a state
            // and will include this in the new state.
            POLYUNSIGNED size = (space->top-space->bottom)/4;
            if (space->isMutable)
                defaultMutSize += size;
            else
                defaultImmSize += size;
            if (space->hierarchy == 0 && ! space->isMutable)
            {
                // We need a separate area for the tombstones because this is read-only
                graveYard[tombs].graves = (PolyWord*)calloc(space->spaceSize(), sizeof(PolyWord));
                if (graveYard[tombs].graves == 0)
                    throw MemoryException();
                graveYard[tombs].startAddr = space->bottom;
                graveYard[tombs].endAddr = space->top;
                tombs++;
            }
        }
    }
    for (i = 0; i < gMem.nlSpaces; i++)
    {
        LocalMemSpace *space = gMem.lSpaces[i];
        POLYUNSIGNED size = space->allocatedSpace();
        // It looks as though the mutable size generally gets
        // overestimated while the immutable size is correct.
        if (space->isMutable)
            defaultMutSize += size/4;
        else
            defaultImmSize += size/2;
    }
    if (isExport)
    {
        // Minimum 1M words.
        if (defaultMutSize < 1024*1024) defaultMutSize = 1024*1024;
        if (defaultImmSize < 1024*1024) defaultImmSize = 1024*1024;
    }
    else
    {
        // Much smaller minimum sizes for saved states.
        if (defaultMutSize < 1024) defaultMutSize = 1024;
        if (defaultImmSize < 4096) defaultImmSize = 4096;
    }
}

CopyScan::~CopyScan()
{
    gMem.DeleteExportSpaces();
    if (graveYard)
        delete[](graveYard);
}


// This function is called for each address in an object
// once it has been copied to its new location.  We copy first
// then scan to update the addresses.
POLYUNSIGNED CopyScan::ScanAddressAt(PolyWord *pt)
{
    PolyWord val = *pt;
    // Ignore integers.
    if (IS_INT(val) || val == PolyWord::FromUnsigned(0))
        return 0;
    // Ignore pointers to the IO area.  They will be relocated
    // when we write out the memory
    MemSpace *space = gMem.SpaceForAddress(val.AsAddress());
    ASSERT(space != 0);
    if (space->spaceType == ST_IO)
        return 0;

    // We may sometimes get addresses that have already been updated
    // to point to the new area.  e.g. (only?) in the case of constants
    // that have been updated in ScanConstantsWithinCode.
    if (space->spaceType == ST_EXPORT)
        return 0;

    // If this is at a lower level than the hierarchy we are saving
    // then leave it untouched.
    if (space->spaceType == ST_PERMANENT)
    {
        PermanentMemSpace *pmSpace = (PermanentMemSpace*)space;
        if (pmSpace->hierarchy < hierarchy)
            return 0;
    }

    if (val.IsCodePtr())
    {
        // Find the start of the code segment
        PolyObject *oldObject = ObjCodePtrToPtr(val.AsCodePtr());
        // Calculate the byte offset of this value within the code object.
        POLYUNSIGNED offset = val.AsCodePtr() - (byte*)oldObject;
        PolyObject *newObject = ScanObjectAddress(oldObject);
        *pt = PolyWord::FromCodePtr((byte*)newObject + offset);
        return 0;
    }

    ASSERT(OBJ_IS_DATAPTR(val));

    // Have we already scanned this?
    PolyObject *obj = val.AsObjPtr();
    if (obj->ContainsForwardingPtr())
    {
        // Update the address to the new value.
        PolyObject *newAddr = obj->GetForwardingPtr();
        *pt = newAddr;
        return 0; // No need to scan it again.
    }
    else if (space->spaceType == ST_PERMANENT)
    {
        // See if we have this in the grave-yard.
        for (unsigned i = 0; i < tombs; i++)
        {
            GraveYard *g = &graveYard[i];
            if (val.AsStackAddr() >= g->startAddr && val.AsStackAddr() < g->endAddr)
            {
                PolyWord *tombAddr = g->graves + (val.AsStackAddr() - g->startAddr);
                PolyObject *tombObject = (PolyObject*)tombAddr;
                if (tombObject->ContainsForwardingPtr())
                {
                    *pt = tombObject->GetForwardingPtr();;
                    return 0;
                }
                break; // No need to look further
            }
        }
    }

    // No, we need to copy it.
    ASSERT(space->spaceType == ST_LOCAL || space->spaceType == ST_PERMANENT);
    POLYUNSIGNED lengthWord = obj->LengthWord();
    POLYUNSIGNED words = OBJ_OBJECT_LENGTH(lengthWord);

    PolyObject *newObj = 0;
    bool isMutableObj = obj->IsMutable();
    bool isNoOverwrite = false;
    bool isByteObj = false;
    if (isMutableObj)
    {
        isNoOverwrite = obj->IsNoOverwriteObject();
        isByteObj = obj->IsByteObject();
    }
    // Allocate a new address for the object.
    for (unsigned i = 0; i < gMem.neSpaces; i++)
    {
        PermanentMemSpace *space = gMem.eSpaces[i];
        if (isMutableObj == space->isMutable &&
            isNoOverwrite == space->noOverwrite &&
            isByteObj == space->byteOnly)
        {
            ASSERT(space->topPointer <= space->top && space->topPointer >= space->bottom);
            POLYUNSIGNED spaceLeft = space->top - space->topPointer;
            if (spaceLeft > words)
            {
                newObj = (PolyObject*)(space->topPointer+1);
                space->topPointer += words+1;
                break;
            }
        }
    }
    if (newObj == 0)
    {
        // Didn't find room in the existing spaces.  Create a new space.
        POLYUNSIGNED spaceWords;
        if (!isMutableObj) spaceWords = defaultImmSize;
        else if (isNoOverwrite) spaceWords = defaultNoOverSize;
        else spaceWords = defaultMutSize;
        if (spaceWords <= words)
            spaceWords = words+1; // Make sure there's space for this object.
        PermanentMemSpace *space = gMem.NewExportSpace(spaceWords, isMutableObj, isNoOverwrite);
        if (isByteObj) space->byteOnly = true;
        if (space == 0)
        {
            // Unable to allocate this.
            throw MemoryException();
        }
        newObj = (PolyObject*)(space->topPointer+1);
        space->topPointer += words+1;
        ASSERT(space->topPointer <= space->top && space->topPointer >= space->bottom);
    }

    newObj->SetLengthWord(lengthWord); // copy length word

    memcpy(newObj, obj, words*sizeof(PolyWord));

    if (space->spaceType == ST_PERMANENT && !space->isMutable && ((PermanentMemSpace*)space)->hierarchy == 0)
    {
        // The immutable permanent areas are read-only.
        unsigned m;
        for (m = 0; m < tombs; m++)
        {
            GraveYard *g = &graveYard[m];
            if (val.AsStackAddr() >= g->startAddr && val.AsStackAddr() < g->endAddr)
            {
                PolyWord *tombAddr = g->graves + (val.AsStackAddr() - g->startAddr);
                PolyObject *tombObject = (PolyObject*)tombAddr;
                tombObject->SetForwardingPtr(newObj);
                break; // No need to look further
            }
        }
        ASSERT(m < tombs); // Should be there.
    }
    else obj->SetForwardingPtr(newObj); // Put forwarding pointer in old object.

    if (OBJ_IS_CODE_OBJECT(lengthWord))
    {
        // We don't need to worry about flushing the instruction cache
        // since we're not going to execute this code here.
        // We do have to update any relative addresses within the code
        // to take account of its new position.  We have to do that now
        // even though ScanAddressesInObject will do it again because this
        // is the only point where we have both the old and the new addresses.
        machineDependent->ScanConstantsWithinCode(newObj, obj, words, this);
    }
    *pt = newObj; // Update it to the newly copied object.
    return lengthWord;  // This new object needs to be scanned.
}


PolyObject *CopyScan::ScanObjectAddress(PolyObject *base)
{
    PolyWord val = base;
    // Scan this as an address. 
    POLYUNSIGNED lengthWord = CopyScan::ScanAddressAt(&val);
    if (lengthWord)
        ScanAddressesInObject(val.AsObjPtr(), lengthWord);
    return val.AsObjPtr();
}

// We clear the data in weak byte ref cells when they are exported
// to an object file and also when they are read from a saved state.
void ClearWeakByteRef::ScanAddressesInObject(PolyObject *base, POLYUNSIGNED lengthWord)
{
    if (OBJ_IS_MUTABLE_OBJECT(lengthWord) && OBJ_IS_BYTE_OBJECT(lengthWord) && OBJ_IS_WEAKREF_OBJECT(lengthWord))
        memset(base, 0, base->Length() * sizeof(PolyWord));
}

#define MAX_EXTENSION   4 // The longest extension we may need to add is ".obj"

// Convert the forwarding pointers in a region back into length words.

// Generally if this object has a forwarding pointer that's
// because we've moved it into the export region.  We can,
// though, get multiple levels of forwarding if there is an object
// that has been shifted up by a garbage collection, leaving a forwarding
// pointer and then that object has been moved to the export region.
// We mustn't turn locally forwarded values back into ordinary objects
// because they could contain addresses that are no longer valid.
static POLYUNSIGNED GetObjLength(PolyObject *obj)
{
    if (obj->ContainsForwardingPtr())
    {
        PolyObject *forwardedTo = obj->GetForwardingPtr();
        POLYUNSIGNED length = GetObjLength(forwardedTo);
        MemSpace *space = gMem.SpaceForAddress(forwardedTo);
        if (space->spaceType == ST_EXPORT)
            obj->SetLengthWord(length);
        return length;
    }
    else {
        ASSERT(obj->ContainsNormalLengthWord());
        return obj->LengthWord();
    }
}

static void FixForwarding(PolyWord *pt, POLYUNSIGNED space)
{
    while (space)
    {
        pt++;
        PolyObject *obj = (PolyObject*)pt;
        POLYUNSIGNED length = OBJ_OBJECT_LENGTH(GetObjLength(obj));
        pt += length;
        ASSERT(space > length);
        space -= length+1;
    }
}

class ExportRequest: public MainThreadRequest
{
public:
    ExportRequest(Handle root, Exporter *exp): MainThreadRequest(MTP_EXPORTING),
        exportRoot(root), exporter(exp) {}

    virtual void Perform() { exporter->RunExport(exportRoot->WordP()); }
    Handle exportRoot;
    Exporter *exporter;
};

static void exporter(TaskData *taskData, Handle args, const TCHAR *extension, Exporter *exports)
{
    TCHAR fileNameBuff[MAXPATHLEN+MAX_EXTENSION];
    POLYUNSIGNED length =
        Poly_string_to_C(DEREFHANDLE(args)->Get(0), fileNameBuff, MAXPATHLEN);
    if (length > MAXPATHLEN)
        raise_syscall(taskData, "File name too long", ENAMETOOLONG);

    // Does it already have the extension?  If not add it on.
    if (length < _tcslen(extension) || _tcscmp(fileNameBuff + length - _tcslen(extension), extension) != 0)
        _tcscat(fileNameBuff, extension);
#if (defined(_WIN32) && defined(UNICODE))
    exports->exportFile = _wfopen(fileNameBuff, L"wb");
#else
    exports->exportFile = fopen(fileNameBuff, "wb");
#endif
    if (exports->exportFile == NULL)
        raise_syscall(taskData, "Cannot open export file", errno);

    Handle root = taskData->saveVec.push(args->WordP()->Get(1));

    // Request a full GC  to reduce the size of fix-ups.
    FullGC(taskData);
    // Request the main thread to do the export.
    ExportRequest request(root, exports);
    processes->MakeRootRequest(taskData, &request);
    if (exports->errorMessage)
        raise_fail(taskData, exports->errorMessage);
}

// This is called by the initial thread to actually do the export.
void Exporter::RunExport(PolyObject *rootFunction)
{
    Exporter *exports = this;

    PolyObject *copiedRoot = 0;
    CopyScan copyScan(hierarchy);

    try {
        copyScan.initialise();
        // Copy the root and everything reachable from it into the temporary area.
        copiedRoot = copyScan.ScanObjectAddress(rootFunction);
    }
    catch (MemoryException &)
    {
        // If we ran out of memory.
        copiedRoot = 0;
    }

    // Fix the forwarding pointers.
    unsigned j;
    for (j = 0; j < gMem.nlSpaces; j++)
    {
        LocalMemSpace *space = gMem.lSpaces[j];
        // Local areas only have objects from the allocation pointer to the top.
        FixForwarding(space->bottom, space->lowerAllocPtr - space->bottom);
        FixForwarding(space->upperAllocPtr, space->top - space->upperAllocPtr);
    }
    for (j = 0; j < gMem.npSpaces; j++)
    {
        MemSpace *space = gMem.pSpaces[j];
        // Permanent areas are filled with objects from the bottom.
        FixForwarding(space->bottom, space->top - space->bottom);
    }

    // Reraise the exception after cleaning up the forwarding pointers.
    if (copiedRoot == 0)
    {
        exports->errorMessage = "Insufficient Memory";
        return;
    }

    // Copy the areas into the export object.
    unsigned tableEntries = gMem.neSpaces, memEntry = 0;
    if (hierarchy != 0) tableEntries += gMem.npSpaces;
    tableEntries++; // One extra for the IO area
    exports->memTable = new memoryTableEntry[tableEntries];
    exports->ioMemEntry = 0;

    // The IO vector.  Should we actually create a blank area?  This needs to be
    // writable by the RTS but not normally by ML.
    MemSpace *ioSpace = gMem.IoSpace();
    exports->memTable[0].mtAddr = ioSpace->bottom;
    exports->memTable[0].mtLength = (char*)ioSpace->top - (char*)ioSpace->bottom;
    exports->memTable[0].mtFlags = MTF_WRITEABLE; // Needs to be written during initialisation.
    exports->memTable[0].mtIndex = 0;
    memEntry = 1;

    // If we're constructing a module we need to include the global spaces.
    if (hierarchy != 0)
    {
        // Permanent spaces from the executable.
        for (unsigned i = 0; i < gMem.npSpaces; i++)
        {
            PermanentMemSpace *space = gMem.pSpaces[i];
            if (space->hierarchy < hierarchy)
            {
                memoryTableEntry *entry = &exports->memTable[memEntry++];
                entry->mtAddr = space->bottom;
                entry->mtLength = (space->topPointer-space->bottom)*sizeof(PolyWord);
                entry->mtIndex = space->index;
                entry->mtFlags = space->isMutable ? MTF_WRITEABLE : 0; 
            }
        }
        newAreas = memEntry;
    }

    for (unsigned i = 0; i < gMem.neSpaces; i++)
    {
        memoryTableEntry *entry = &exports->memTable[memEntry++];
        PermanentMemSpace *space = gMem.eSpaces[i];
        entry->mtAddr = space->bottom;
        entry->mtLength = (space->topPointer-space->bottom)*sizeof(PolyWord);
        entry->mtIndex = hierarchy == 0 ? memEntry-1 : space->index;
        if (space->isMutable)
        {
            entry->mtFlags = MTF_WRITEABLE;
            if (space->noOverwrite) entry->mtFlags |= MTF_NO_OVERWRITE;
        }
        else
            entry->mtFlags = MTF_EXECUTABLE;
        if (space->byteOnly) entry->mtFlags |= MTF_BYTES;
        if (space->isMutable && space->byteOnly)
        {
            ClearWeakByteRef cwbr;
            cwbr.ScanAddressesInRegion(space->bottom, space->topPointer);
        }
    }

    ASSERT(memEntry == tableEntries);
    exports->memTableEntries = memEntry;

    exports->ioSpacing = IO_SPACING;
    exports->rootFunction = copiedRoot;

    exports->exportStore();
    return;
}

// Functions called via the RTS call.
Handle exportNative(TaskData *taskData, Handle args)
{
#ifdef HAVE_PECOFF
    // Windows including Cygwin
#if (defined(_WIN32) && ! defined(__CYGWIN__))
    const TCHAR *extension = _T(".obj"); // Windows
#else
    const char *extension = ".o"; // Cygwin
#endif
    PECOFFExport exports;
    exporter(taskData, args, extension, &exports);
#elif defined(HAVE_ELF_H) || defined(HAVE_ELF_ABI_H)
    // Most Unix including Linux, FreeBSD and Solaris.
    const char *extension = ".o";
    ELFExport exports;
    exporter(taskData, args, extension, &exports);
#elif defined(HAVE_MACH_O_RELOC_H)
    // Mac OS-X
    const char *extension = ".o";
    MachoExport exports;
    exporter(taskData, args, extension, &exports);
#else
    raise_exception_string (taskData, EXC_Fail, "Native export not available for this platform");
#endif
    return taskData->saveVec.push(TAGGED(0));
}

Handle exportPortable(TaskData *taskData, Handle args)
{
    PExport exports;
    exporter(taskData, args, _T(".txt"), &exports);
    return taskData->saveVec.push(TAGGED(0));
}


// Helper functions for exporting.  We need to produce relocation information
// and this code is common to every method.
Exporter::Exporter(unsigned int h): exportFile(NULL), errorMessage(0), hierarchy(h), memTable(0), newAreas(0)
{
}

Exporter::~Exporter()
{
    delete[](memTable);
    if (exportFile)
        fclose(exportFile);
}

void Exporter::relocateValue(PolyWord *pt)
{
    PolyWord q = *pt;
    if (IS_INT(q) || q == PolyWord::FromUnsigned(0)) {}
    else createRelocation(pt);
}

// Check through the areas to see where the address is.  It must be
// in one of them.
unsigned Exporter::findArea(void *p)
{
    for (unsigned i = 0; i < memTableEntries; i++)
    {
        if (p > memTable[i].mtAddr &&
            p <= (char*)memTable[i].mtAddr + memTable[i].mtLength)
            return i;
    }
    { ASSERT(0); }
    return 0;
}

void Exporter::relocateObject(PolyObject *p)
{
    if (p->IsByteObject())
    {
    }
    else if (p->IsCodeObject())
    {
        POLYUNSIGNED constCount;
        PolyWord *cp;
        ASSERT(! p->IsMutable() );
        p->GetConstSegmentForCode(cp, constCount);
        /* Now the constants. */
        for (POLYUNSIGNED i = 0; i < constCount; i++) relocateValue(&(cp[i]));

    }
    else /* Ordinary objects, essentially tuples. */
    {
        POLYUNSIGNED length = p->Length();
        for (POLYUNSIGNED i = 0; i < length; i++) relocateValue(p->Offset(i));
    }
}

ExportStringTable::ExportStringTable(): strings(0), stringSize(0), stringAvailable(0)
{
}

ExportStringTable::~ExportStringTable()
{
    free(strings);
}

// Add a string to the string table, growing it if necessary.
unsigned long ExportStringTable::makeEntry(const char *str)
{
    unsigned len = (unsigned)strlen(str);
    unsigned long entry = stringSize;
    if (stringSize + len + 1 > stringAvailable)
    {
        stringAvailable = stringAvailable+stringAvailable/2;
        if (stringAvailable < stringSize + len + 1)
            stringAvailable = stringSize + len + 1 + 500;
        strings = (char*)realloc(strings, stringAvailable);
        if (strings == 0)
            throw MemoryException();
     }
    strcpy(strings + stringSize, str);
    stringSize += len + 1;
    return entry;
}

