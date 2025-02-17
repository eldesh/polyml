/*
    Title:      Process environment.
    Copyright (c) 2000-8
        David C. J. Matthews

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.
    
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

#ifdef HAVE_STDIO_H
#include <stdio.h>
#endif

#ifdef HAVE_ERRNO_H
#include <errno.h>
#endif

#ifdef HAVE_STRING_H
#include <string.h>
#endif

#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef HAVE_SYS_PARAM_H
#include <sys/param.h>
#endif

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif

#ifdef HAVE_SYS_WAIT_H
#include <sys/wait.h>
#endif

#if (defined(__CYGWIN__) || defined(_WIN32))
#include <process.h>
#endif

// Include this next before errors.h since in WinCE at least the winsock errors are defined there.
#if (defined(_WIN32) && ! defined(__CYGWIN__))
#ifdef USEWINSOCK2
#include <winsock2.h>
#else
#include <winsock.h>
#endif
#endif

#ifdef HAVE_TCHAR_H
#include <tchar.h>
#else
typedef char TCHAR;
#define _tgetenv getenv
#endif


#include "globals.h"
#include "sys.h"
#include "run_time.h"
#include "process_env.h"
#include "arb.h"
#include "mpoly.h"
#include "gc.h"
#include "scanaddrs.h"
#include "polystring.h"
#include "save_vec.h"
#include "process_env.h"
#include "rts_module.h"
#include "machine_dep.h"
#include "processes.h"
#include "locking.h"
#include "errors.h"

#include "poly_specific.h" // For the functions that have been moved.

#define SAVE(x) mdTaskData->saveVec.push(x)
#define ALLOC(n) alloc_and_save(mdTaskData, n)

#if (defined(_WIN32) && ! defined(__CYGWIN__))
#define ISPATHSEPARATOR(c)  ((c) == '\\' || (c) == '/')
#define DEFAULTSEPARATOR    "\\"
#else
#define ISPATHSEPARATOR(c)  ((c) == '/')
#define DEFAULTSEPARATOR    "/"
#endif

#ifdef _MSC_VER
// Don't tell me about ISO C++ changes.
#pragma warning(disable:4996)
#endif

// "environ" is declared in the headers on some systems but not all.
// Oddly, declaring it within process_env_dispatch_c causes problems
// on mingw where "environ" is actually a function.
#if __APPLE__
// On Mac OS X there may be problems accessing environ directly.
#include <crt_externs.h>
#define environ (*_NSGetEnviron())
#else
extern char **environ;
#endif

/* Functions registered with atExit are added to this list. */
static PolyWord at_exit_list = TAGGED(0);
/* Once "exit" is called this flag is set and no further
   calls to atExit are allowed. */
static bool exiting = false;

static PLock atExitLock; // Thread lock for above.

#ifdef __CYGWIN__
// Cygwin requires spawnvp to avoid the significant overhead of vfork
// but it doesn't seem to be thread-safe.  Run it on the main thread
// to be sure.
class CygwinSpawnRequest: public MainThreadRequest
{
public:
    CygwinSpawnRequest(char **argv): MainThreadRequest(MTP_CYGWINSPAWN), spawnArgv(argv) {}

    virtual void Perform();
    char **spawnArgv;
    int pid;
};

void CygwinSpawnRequest::Perform()
{
    pid = spawnvp(_P_NOWAIT, "/bin/sh", spawnArgv);
}

#endif

Handle process_env_dispatch_c(TaskData *mdTaskData, Handle args, Handle code)
{
    unsigned c = get_C_unsigned(mdTaskData, DEREFWORDHANDLE(code));
    switch (c)
    {
    case 0: /* Return the program name. */
        return SAVE(C_string_to_Poly(mdTaskData, userOptions.programName));

    case 1: /* Return the argument list. */
        return convert_string_list(mdTaskData, userOptions.user_arg_count, userOptions.user_arg_strings);

    case 14: /* Return a string from the environment. */
        {
            TempString buff(args->Word());
            if (buff == 0) raise_syscall(mdTaskData, "Insufficient memory", ENOMEM);
            TCHAR *res = _tgetenv(buff);
            if (res == NULL) raise_syscall(mdTaskData, "Not Found", 0);
            else return SAVE(C_string_to_Poly(mdTaskData, res));
        }

    case 21: // Return the whole environment.  Only available in Posix.ProcEnv.
        {
            /* Count the environment strings */
            int env_count = 0;
            while (environ[env_count] != NULL) env_count++;
            return convert_string_list(mdTaskData, env_count, environ);
        }

    case 15: /* Return the success value. */
        return Make_arbitrary_precision(mdTaskData, EXIT_SUCCESS);

    case 16: /* Return a failure value. */
        return Make_arbitrary_precision(mdTaskData, EXIT_FAILURE);

    case 17: /* Run command. */
        {
            TempString buff(args->Word());
            if (buff == 0) raise_syscall(mdTaskData, "Insufficient memory", ENOMEM);
            int res = -1;
#if (defined(_WIN32) && ! defined(__CYGWIN__))
            // Windows.
            TCHAR *argv[4];
            argv[0] = _tgetenv(_T("COMSPEC")); // Default CLI.
            if (argv[0] == 0) argv[0] = (TCHAR*)_T("cmd.exe"); // Win NT etc.
            argv[1] = (TCHAR*)_T("/c");
            argv[2] = buff;
            argv[3] = NULL;
            // If _P_NOWAIT is given the result is the process handle.
            // spawnvp does any necessary path searching if argv[0]
            // does not contain a full path.
            intptr_t pid = _tspawnvp(_P_NOWAIT, argv[0], argv);
            if (pid == -1)
                raise_syscall(mdTaskData, "Function system failed", errno);
#else
            // Cygwin and Unix
            char *argv[4];
            argv[0] = (char*)"sh";
            argv[1] = (char*)"-c";
            argv[2] = buff;
            argv[3] = NULL;
#if (defined(__CYGWIN__))
            CygwinSpawnRequest request(argv);
            processes->MakeRootRequest(mdTaskData, &request);
            int pid = request.pid;
            if (pid < 0)
                raise_syscall(mdTaskData, "Function system failed", errno);
#else
            // We need to break this down so that we can unblock signals in the
            // child process.
            // The Unix "system" function seems to set SIGINT and SIGQUIT to
            // SIG_IGN in the parent so that the wait will not be interrupted.
            // That may make sense in a single-threaded application but is
            // that right here?
            int pid = vfork();
            if (pid == -1)
                raise_syscall(mdTaskData, "Function system failed", errno);
            else if (pid == 0)
            { // In child
                sigset_t sigset;
                sigemptyset(&sigset);
                sigprocmask(SIG_SETMASK, &sigset, 0);
                // Reset other signals?
                execve("/bin/sh", argv, environ);
                _exit(1);
            }
#endif
#endif
            while (true)
            {
                try
                {
                // Test to see if the child has returned.
#if (defined(_WIN32) && ! defined(__CYGWIN__))
                    switch (WaitForSingleObject((HANDLE)pid, 0))
                    {
                    case WAIT_OBJECT_0:
                        {
                            DWORD result;
                            BOOL fResult = GetExitCodeProcess((HANDLE)pid, &result);
                            if (! fResult)
                                raise_syscall(mdTaskData, "Function system failed", -(int)GetLastError());
                            CloseHandle((HANDLE)pid);
                            return Make_arbitrary_precision(mdTaskData, result);
                        }
                    case WAIT_FAILED:
                        raise_syscall(mdTaskData, "Function system failed", -(int)GetLastError());
                    }
                    // Wait for the process to exit or for the timeout
                    WaitHandle waiter((HANDLE)pid);
                    processes->ThreadPauseForIO(mdTaskData, &waiter);
#else
                    int wRes = waitpid(pid, &res, WNOHANG);
                    if (wRes > 0)
                        break;
                    else if (wRes < 0)
                    {
                        raise_syscall(mdTaskData, "Function system failed", errno);
                    }
                    // In Unix the best we can do is wait.  This may be interrupted
                    // by SIGCHLD depending on where signals are processed.
                    // One possibility is for the main thread to somehow wake-up
                    // the thread when it processes a SIGCHLD.
                    processes->ThreadPause(mdTaskData);
#endif
                }
                catch (...)
                {
                    // Either IOException or KillException.
                    // We're abandoning the wait.  This will leave
                    // a zombie in Unix.
#if (defined(_WIN32) && ! defined(__CYGWIN__))
                    CloseHandle((HANDLE)pid);
#endif
                    throw;
                }
            }
            return Make_arbitrary_precision(mdTaskData, res);
        }

    case 18: /* Register function to run at exit. */
        {
            PLocker locker(&atExitLock);
            if (! exiting)
            {
                PolyObject *cell = alloc(mdTaskData, 2);
                cell->Set(0, at_exit_list);
                cell->Set(1, DEREFWORD(args));
                at_exit_list = cell;
            }
            return Make_arbitrary_precision(mdTaskData, 0);
        }

    case 19: /* Return the next function in the atExit list and set the
                "exiting" flag to true. */
        {
            PLocker locker(&atExitLock);
            Handle res;
            exiting = true; /* Ignore further calls to atExit. */
            if (at_exit_list == TAGGED(0))
                raise_syscall(mdTaskData, "List is empty", 0);
            PolyObject *cell = at_exit_list.AsObjPtr();
            res = SAVE(cell->Get(1));
            at_exit_list = cell->Get(0);
            return res;
        }

    case 20: /* Terminate without running the atExit list or flushing buffers. */
        {
            /* I don't like terminating without some sort of clean up
               but we'll do it this way for the moment. */
            int i = get_C_int(mdTaskData, DEREFWORDHANDLE(args));
            _exit(i);
        }

        /************ Error codes **************/

    case 2: /* Get the name of a numeric error message. */
        {
            char buff[40];
            int e = get_C_int(mdTaskData, DEREFWORDHANDLE(args));
            Handle  res;
            /* First look to see if we have the name in
               the error table. They should generally all be
               there. */
            const char *errorMsg = stringFromErrorCode(e);
            if (errorMsg != NULL)
                return SAVE(C_string_to_Poly(mdTaskData, errorMsg));
            /* We get here if there's an error which isn't in the table. */
#if (defined(_WIN32) && ! defined(__CYGWIN__))
            /* In the Windows version we may have both errno values
               and also GetLastError values.  We convert the latter into
               negative values before returning them. */
            if (e < 0)
            {
                sprintf(buff, "WINERROR%0d", -e);
                res = SAVE(C_string_to_Poly(mdTaskData, buff));
                return res;
            }
            else
#endif
            {
                sprintf(buff, "ERROR%0d", e);
                res = SAVE(C_string_to_Poly(mdTaskData, buff));
            }
            return res;
        }

    case 3: /* Get the explanatory message for an error. */
        {
            return errorMsg(mdTaskData, get_C_int(mdTaskData, DEREFWORDHANDLE(args)));
        }

    case 4: /* Try to convert an error string to an error number. */
        {
            char buff[40];
            /* Get the string. */
            Poly_string_to_C(DEREFWORD(args), buff, sizeof(buff));
            /* Look the string up in the table. */
            int err = 0;
            if (errorCodeFromString(buff, &err))
                return Make_arbitrary_precision(mdTaskData, err);
            /* If we don't find it then it may have been a constructed
               error name. */
            if (strncmp(buff, "ERROR", 5) == 0)
            {
                int i = atoi(buff+5);
                if (i > 0) return Make_arbitrary_precision(mdTaskData, i);
            }
#if (defined(_WIN32) && ! defined(__CYGWIN__))
            if (strncmp(buff, "WINERROR", 8) == 0)
            {
                int i = atoi(buff+8);
                if (i > 0) return Make_arbitrary_precision(mdTaskData, -i);
            }
#endif
            return Make_arbitrary_precision(mdTaskData, 0);
        }

        /************ Directory/file paths **************/

    case 5: /* Return the string representing the current arc. */
        return SAVE(C_string_to_Poly(mdTaskData, "."));

    case 6: /* Return the string representing the parent arc. */
        /* I don't know that this exists in MacOS. */
        return SAVE(C_string_to_Poly(mdTaskData, ".."));

    case 7: /* Return the string representing the directory separator. */
        return SAVE(C_string_to_Poly(mdTaskData, DEFAULTSEPARATOR));

    case 8: /* Test the character to see if it matches a separator. */
        {
            int e = get_C_int(mdTaskData, DEREFWORDHANDLE(args));
            if (ISPATHSEPARATOR(e))
                return Make_arbitrary_precision(mdTaskData, 1);
            else return Make_arbitrary_precision(mdTaskData, 0);
        }

    case 9: /* Are names case-sensitive? */
#if (defined(_WIN32) && ! defined(__CYGWIN__))
        /* Windows - no. */
        return Make_arbitrary_precision(mdTaskData, 0);
#else
        /* Unix - yes. */
        return Make_arbitrary_precision(mdTaskData, 1);
#endif

        // These are no longer used.  The code is handled entirely in ML.
    case 10: /* Are empty arcs redundant? */
        /* Unix and Windows - yes. */
        return Make_arbitrary_precision(mdTaskData, 1);

    case 11: /* Match the volume name part of a path. */
        {
            const TCHAR *volName = NULL;
            int  isAbs = 0;
            int  toRemove = 0;
            PolyWord path = DEREFHANDLE(args);
            /* This examines the start of a string and determines
               how much of it represents the volume name and returns
               the number of characters to remove, the volume name
               and whether it is absolute.
               One would assume that if there is a volume name then it
               is absolute but there is a peculiar form in Windows/DOS
               (e.g. A:b\c) which means the file b\c relative to the
               currently selected directory on the volume A.
            */
#if (defined(_WIN32) && ! defined(__CYGWIN__))
            TempString buff(path);
            if (buff == 0) raise_syscall(mdTaskData, "Insufficient memory", ENOMEM);
            size_t length = _tcslen(buff);
            if (length >= 2 && buff[1] == ':')
            { /* Volume name? */
                if (length >= 3 && ISPATHSEPARATOR(buff[2]))
                {
                    /* Absolute path. */
                    toRemove = 3; isAbs = 1;
                }
                else { toRemove = 2; isAbs = 0; }
                volName = buff; buff[2] = '\0';
            }
            else if (length > 3 &&
                     ISPATHSEPARATOR(buff[0]) &&
                     ISPATHSEPARATOR(buff[1]) &&
                     ! ISPATHSEPARATOR(buff[2]))
            { /* UNC name? */
                int i;
                /* Skip the server name. */
                for (i = 3; buff[i] != 0 && !ISPATHSEPARATOR(buff[i]); i++);
                if (ISPATHSEPARATOR(buff[i]))
                {
                    i++;
                    /* Skip the share name. */
                    for (; buff[i] != 0 && !ISPATHSEPARATOR(buff[i]); i++);
                    toRemove = i;
                    if (buff[i] != 0) toRemove++;
                    isAbs = 1;
                    volName = buff;
                    buff[i] = '\0';
                }
            }
            else if (ISPATHSEPARATOR(buff[0]))
                /* \a\b strictly speaking is relative to the
                   current drive.  It's much easier to treat it
                   as absolute. */
                { toRemove = 1; isAbs = 1; volName = _T(""); }
#else
            /* Unix - much simpler. */
            char toTest = 0;
            if (IS_INT(path)) toTest = UNTAGGED(path);
            else {
                PolyStringObject * ps = (PolyStringObject *)path.AsObjPtr();
                if (ps->length > 1) toTest = ps->chars[0];
            }
            if (ISPATHSEPARATOR(toTest))
                { toRemove = 1; isAbs = 1; volName = ""; }
#endif
            /* Construct the result. */
            {
                Handle sVol = SAVE(C_string_to_Poly(mdTaskData, volName));
                Handle sRes = ALLOC(3);
                DEREFWORDHANDLE(sRes)->Set(0, TAGGED(toRemove));
                DEREFHANDLE(sRes)->Set(1, DEREFWORDHANDLE(sVol));
                DEREFWORDHANDLE(sRes)->Set(2, TAGGED(isAbs));
                return sRes;
            }
        }

    case 12: /* Construct a name from a volume and whether it is
                absolute. */
        {
            unsigned isAbs = get_C_unsigned(mdTaskData, DEREFHANDLE(args)->Get(1));
            PolyWord volName = DEREFHANDLE(args)->Get(0);
            /* In Unix the volume name will always be empty. */
            if (isAbs == 0)
                return SAVE(volName);
            /* N.B. The arguments to strconcatc are in reverse. */
            else return strconcatc(mdTaskData,
                                   SAVE(C_string_to_Poly(mdTaskData, DEFAULTSEPARATOR)),
                                   SAVE(volName));
        }

    case 13: /* Is the string a valid file name? */
        {
            PolyWord volName = DEREFWORD(args);
            // First check for NULL.  This is not allowed in either Unix or Windows.
            if (IS_INT(volName))
            {
                if (volName == TAGGED(0))
                    return Make_arbitrary_precision(mdTaskData, 0);
            }
            else
            {
                PolyStringObject * volume = (PolyStringObject *)(volName.AsObjPtr());
                for (POLYUNSIGNED i = 0; i < volume->length; i++)
                {
                    if (volume->chars[i] == '\0')
                        return Make_arbitrary_precision(mdTaskData, 0);
                }
            }
#if (defined(_WIN32) && ! defined(__CYGWIN__))
            // We need to look for certain invalid characters but only after
            // we've converted it to Unicode if necessary.
            TempString name(volName);
            for (const TCHAR *p = name; *p != 0; p++)
            {
                switch (*p)
                {
                case '<': case '>': case ':': case '"': 
                case '\\': case '|': case '?': case '*': case '\0':
#if (0)
                // This currently breaks the build.
                case '/':
#endif
                    return Make_arbitrary_precision(mdTaskData, 0);
                }
                if (*p >= 0 && *p <= 31) return Make_arbitrary_precision(mdTaskData, 0);
            }
            // Should we check for special names such as aux, con, prn ??
            return Make_arbitrary_precision(mdTaskData, 1);
#else
            // That's all we need for Unix.
            // TODO: Check for /.  It's invalid in a file name arc.
            return Make_arbitrary_precision(mdTaskData, 1);
#endif
        }

        // A group of calls have now been moved to poly_specific.
        // This entry is returned for backwards compatibility.
    case 100: case 101: case 102: case 103: case 104: case 105:
        return poly_dispatch_c(mdTaskData, args, code);

    default:
        {
            char msg[100];
            sprintf(msg, "Unknown environment function: %d", c);
            raise_exception_string(mdTaskData, EXC_Fail, msg);
            return 0;
        }
    }
}

/* Terminate normally with a result code. */
Handle finishc(TaskData *taskData, Handle h)
{
    int i = get_C_int(taskData, DEREFWORDHANDLE(h));
    // Cause the other threads to exit.
    processes->Exit(i);
    // Exit this thread
    processes->ThreadExit(taskData); // Doesn't return.
    // Push a dummy result to keep lint happy
    return taskData->saveVec.push(TAGGED(0));
}

class ProcessEnvModule: public RtsModule
{
public:
    void GarbageCollect(ScanAddress *process);
};

// Declare this.  It will be automatically added to the table.
static ProcessEnvModule processModule;

void ProcessEnvModule::GarbageCollect(ScanAddress *process)
/* Ensures that all the objects are retained and their addresses updated. */
{
    if (at_exit_list.IsDataPtr())
    {
        PolyObject *obj = at_exit_list.AsObjPtr();
        process->ScanRuntimeAddress(&obj, ScanAddress::STRENGTH_STRONG);
        at_exit_list = obj;
    }
}
