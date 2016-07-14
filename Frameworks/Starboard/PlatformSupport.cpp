//******************************************************************************
//
// Copyright (c) 2015 Microsoft Corporation. All rights reserved.
//
// This code is licensed under the MIT License (MIT).
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//******************************************************************************

#include <windows.h>
#include <errno.h>
#include <stdio.h>
#include <io.h>
#include <assert.h>
#include <stdlib.h>
#include <direct.h>
#include <sys\stat.h>
#include <map>
#include <regex>

#include "Platform/EbrPlatform.h"
#include "Starboard.h"
#include <pthread.h>
#include "pevents.h"
#include "PathMapper.h"
#include "LoggingNative.h"

static const wchar_t* TAG = L"PlatformSupport";

void EbrBlockIfBackground() {
}

void EbrEventInit(EbrEvent* pEvent) {
    *pEvent = (void*)neosmart::NeoCreateEvent(false, false);
}

void EbrEventSignal(EbrEvent event) {
    neosmart::SetEvent((neosmart::neosmart_event_t)event);
}

void EbrEventWait(EbrEvent event) {
    neosmart::WaitForEvent((neosmart::neosmart_event_t)event);
}

bool EbrEventTryWait(EbrEvent event) {
    if (neosmart::WaitForEvent((neosmart::neosmart_event_t)event, 0) == 0) {
        return TRUE;
    } else {
        return FALSE;
    }
}

bool EbrEventTimedWait(EbrEvent event, double seconds) {
    if (neosmart::WaitForEvent((neosmart::neosmart_event_t)event, seconds * 1000.0) != 0) {
        return FALSE;
    }

    return TRUE;
}

int EbrEventTimedMultipleWait(EbrEvent* events, int numEvents, double timeout, SocketWait* sockets) {
    int signaledEvent;
    if (neosmart::WaitForMultipleEvents(
            (neosmart::neosmart_event_t*)events, numEvents, false, (uint64_t)(timeout * 1000.0), signaledEvent, sockets) != 0) {
        return -1;
    }

    return signaledEvent;
}

void EbrEventDestroy(EbrEvent event) {
    neosmart::DestroyEvent((neosmart::neosmart_event_t)event);
}

int EbrGetWantedOrientation() {
    return 1;
}

EbrFile::EbrFile() {
    idx = -1;
    type = EbrFileTypeUnknown;
}

EbrFile::~EbrFile() {
}

int EbrFile::Close() {
    assert(0);
    return -1;
}

size_t EbrFile::Read(void* dest, size_t elem, size_t count) {
    assert(0);
    return 0;
}

size_t EbrFile::Write(const void* dest, size_t elem, size_t count) {
    assert(0);
    return 0;
}

int EbrFile::Seek(long offset, int origin) {
    assert(0);
    return -1;
}

int EbrFile::Seek64(__int64 offset, int origin) {
    assert(0);
    return -1;
}

size_t EbrFile::Tell() {
    assert(0);
    return 0;
}

int EbrFile::Eof() {
    assert(0);
    return 1;
}

int EbrFile::Putc(int c) {
    assert(0);
    return -1;
}

int EbrFile::Rewind() {
    assert(0);
    return -1;
}

int EbrFile::Error() {
    assert(0);
    return 1;
}

int EbrFile::Getc() {
    assert(0);
    return 0;
}

int EbrFile::Ungetc(int val) {
    assert(0);
    return 0;
}

char* EbrFile::Gets(char* dest, size_t size) {
    assert(0);
    return NULL;
}

int EbrFile::Puts(const char* str) {
    assert(0);
    return -1;
}

void EbrFile::Clearerr() {
    assert(0);
}

int EbrFile::Flush() {
    assert(0);
    return -1;
}

int EbrFile::Setpos(__int64* pos) {
    assert(0);
    return -1;
}

int EbrFile::Getpos(__int64* pos) {
    assert(0);
    return -1;
}

int EbrFile::HostFd() {
    assert(0);
    return -1;
}

int EbrFile::Stat(struct stat* ret) {
    assert(0);
    return -1;
}

int EbrFile::Read(void* dest, size_t count) {
    assert(0);
    return 0;
}

int EbrFile::Write(const void* src, size_t count) {
    assert(0);
    return 0;
}

int EbrFile::Lseek(__int64 pos, int whence) {
    assert(0);
    return 0;
}

int EbrFile::Truncate(off_t size) {
    assert(0);
    return 0;
}

int EbrFile::Truncate64(__int64 size) {
    assert(0);
    return 0;
}

int EbrFile::Dup() {
    assert(0);
    return -1;
}

void* EbrFile::Mmap(void* addr, size_t size, uint32_t prot, uint32_t flags, uint32_t offset) {
    assert(0);
    return NULL;
}

int EbrFile::Munmap(void* addr, size_t size) {
    assert(0);
    return -1;
}

class EbrFileDevRandom : public EbrFile {
public:
    EbrFileDevRandom() {
    }

    ~EbrFileDevRandom() {
    }

    virtual int Stat(struct stat* ret) {
        memset(ret, 0, sizeof(struct stat));
        return 0;
    }

    virtual int Read(void* dest, size_t count) {
        return -1;
    }

    virtual int Close() {
        return 0;
    }
};

class EbrIOFile : public EbrFile {
public:
    FILE* fp;
    int filefd;
    HANDLE hMapping;

    EbrIOFile();
    ~EbrIOFile();

    virtual int Close();
    virtual size_t Read(void* dest, size_t elem, size_t count);
    virtual size_t Write(const void* dest, size_t elem, size_t count);
    virtual int Seek(long offset, int origin);
    virtual int Seek64(__int64 offset, int origin);
    virtual size_t Tell();
    virtual int Eof();
    virtual int Putc(int c);
    virtual int Rewind();
    virtual int Error();
    virtual int Getc();
    virtual int Ungetc(int val);
    virtual char* Gets(char* dest, size_t size);
    virtual int Puts(const char* str);
    virtual void Clearerr();
    virtual int Flush();
    virtual int Setpos(__int64* pos);
    virtual int Getpos(__int64* pos);

    virtual int HostFd();
    virtual int Stat(struct stat* ret);
    virtual int Read(void* dest, size_t count);
    virtual int Write(const void* src, size_t count);
    virtual int Lseek(__int64 pos, int whence);
    virtual int Truncate(off_t size);
    virtual int Truncate64(__int64 size);
    virtual int Dup();
};

EbrIOFile::EbrIOFile() {
    fp = NULL;
    filefd = -1;
    hMapping = INVALID_HANDLE_VALUE;
    type = EbrFileTypeIO;
}

EbrIOFile::~EbrIOFile() {
    Close();
}

int EbrIOFile::Close() {
    int ret = -1;
    if (fp) {
        ret = fclose(fp);
    } else {
        if (filefd != -1) {
            ret = _close(filefd);
        }
    }
    if (hMapping != INVALID_HANDLE_VALUE) {
        CloseHandle(hMapping);
    }

    fp = NULL;
    filefd = -1;
    hMapping = INVALID_HANDLE_VALUE;

    return ret;
}

#define MAX_OPEN_EBRFILES 512

static EbrFile* _openFiles[MAX_OPEN_EBRFILES];
static int EbrFileHead = 0;
static pthread_mutex_t _EbrFilesLock = PTHREAD_MUTEX_INITIALIZER;
EbrFile* EbrAllocFile(EbrFile* ioInterface) {
    pthread_mutex_lock(&_EbrFilesLock);
    int start = EbrFileHead;

    do {
        if (_openFiles[EbrFileHead] == NULL && EbrFileHead != 0) {
            _openFiles[EbrFileHead] = ioInterface;
            _openFiles[EbrFileHead]->idx = EbrFileHead;

            pthread_mutex_unlock(&_EbrFilesLock);
            return _openFiles[EbrFileHead];
        }

        EbrFileHead = (EbrFileHead + 1) % MAX_OPEN_EBRFILES;
    } while (EbrFileHead != start);

    assert(0);
    return NULL;
}

void EbrFreeFile(EbrFile* pFile) {
    int idx;
    idx = pFile->idx;
    if (idx < 0 || idx >= MAX_OPEN_EBRFILES)
        return;

    delete pFile;
    _openFiles[idx] = NULL;
}

EbrFile* EbrFileFromFd(int fd) {
    if (fd < 0 || fd >= MAX_OPEN_EBRFILES)
        return NULL;

    return _openFiles[fd];
}

EbrFileType EbrFileGetType(EbrFile* pFile) {
    return pFile->type;
}

int EbrIncrement(int volatile* var) {
    return InterlockedIncrement((volatile LONG*)var);
}

int EbrDecrement(int volatile* var) {
    return InterlockedDecrement((volatile LONG*)var);
}

int EbrCompareExchange(int volatile* Destination, int Exchange, int Comperand) {
    return InterlockedCompareExchange((volatile LONG*)Destination, Exchange, Comperand);
}

void EbrSleep(__int64 nanoseconds) {
    EbrBlockIfBackground();
    Sleep((DWORD)(nanoseconds / 1000000LL));
}

#define PTW32_TIMESPEC_TO_FILETIME_OFFSET (((LONGLONG)27111902 << 32) + (LONGLONG)3577643008)

static void filetime_to_timeval(const FILETIME* ft, struct EbrTimeval* ts) {
    ts->tv_sec = (int)((*(LONGLONG*)ft - PTW32_TIMESPEC_TO_FILETIME_OFFSET) / 10000000);
    ts->tv_usec = (int)((*(LONGLONG*)ft - PTW32_TIMESPEC_TO_FILETIME_OFFSET - ((LONGLONG)ts->tv_sec * (LONGLONG)10000000)) / 10);
}

int EbrGetTimeOfDay(struct EbrTimeval* curtime) {
    FILETIME ft;

    GetSystemTimeAsFileTime(&ft);
    filetime_to_timeval(&ft, curtime);

    return 0;
}

//  Stdio funcs
EbrFile* EbrFmake(FILE* fp) {
    EbrIOFile* ret = new EbrIOFile();
    ret->fp = fp;
    ret->filefd = _fileno(fp);
    return EbrAllocFile(ret);
}

EbrFile* EbrFopen(const char* filename, const char* mode) {
    if (strcmp(filename, "/dev/urandom") == 0) {
        EbrFileDevRandom* ret = new EbrFileDevRandom();
        return EbrAllocFile(ret);
    }
    bool stop = false;
    if (stop) {
        return NULL;
    }
    FILE* fp;
    fopen_s(&fp, CPathMapper(filename), mode);
    if (!fp) {
        return NULL;
    }

    EbrIOFile* ret = new EbrIOFile();
    ret->fp = fp;
    ret->filefd = _fileno(fp);
    return EbrAllocFile(ret);
}

//  IO funcs

int EbrOpen(const char* file, int mode, int share) {
    return EbrOpenWithPermission(file, mode, share, 0);
}

int EbrOpenWithPermission(const char* file, int mode, int share, int pmode) {
    if (strcmp(file, "/dev/urandom") == 0) {
        EbrFileDevRandom* ret = new EbrFileDevRandom();
        EbrFile* addedFile = EbrAllocFile(ret);

        return addedFile->idx;
    }

    bool stop = false;
    if (stop) {
        return -1;
    }
    int ret = -1;
    _sopen_s(&ret, CPathMapper(file), mode, share, pmode);
    if (ret == -1) {
        return -1;
    }

    EbrIOFile* newFile = new EbrIOFile();
    newFile->filefd = ret;

    EbrFile* addedFile = EbrAllocFile(newFile);

    return addedFile->idx;
}

int EbrIOFile::HostFd() {
    return filefd;
}

EbrFile* EbrFdopen(int handle, const char* mode) {
    ((EbrIOFile*)_openFiles[handle])->fp = _fdopen(((EbrIOFile*)_openFiles[handle])->HostFd(), mode);

    return _openFiles[handle];
}

/*
int EbrAccess(const char *file, int mode)
{
    return _access(CPathMapper(file), mode);
}
*/

int EbrFclose(EbrFile* file) {
    file->Close();

    EbrFreeFile(file);
    return 0;
}

size_t EbrIOFile::Read(void* dest, size_t elem, size_t count) {
    return fread(dest, elem, count, fp);
}

size_t EbrFread(void* dest, size_t elem, size_t count, EbrFile* file) {
    return file->Read(dest, elem, count);
}

size_t EbrIOFile::Write(const void* dest, size_t elem, size_t count) {
    return fwrite(dest, elem, count, fp);
}

size_t EbrFwrite(const void* dest, size_t elem, size_t count, EbrFile* file) {
    return file->Write(dest, elem, count);
}

int EbrIOFile::Seek(long offset, int origin) {
    return fseek(fp, offset, origin);
}

int EbrFseek(EbrFile* fp, long offset, int origin) {
    return fp->Seek(offset, origin);
}

int EbrIOFile::Seek64(__int64 offset, int origin) {
    return _fseeki64(fp, offset, origin);
}

int EbrFseek64(EbrFile* fp, __int64 offset, int origin) {
    return fp->Seek64(offset, origin);
}

size_t EbrIOFile::Tell() {
    return ftell(fp);
}

size_t EbrFtell(EbrFile* fp) {
    return fp->Tell();
}

int EbrIOFile::Eof() {
    return feof(fp);
}

int EbrFeof(EbrFile* fp) {
    return fp->Eof();
}

/*
int EbrStat(const char *filename, struct stat *ret)
{
    return stat(CPathMapper(filename), ret);
}
*/

int EbrIOFile::Putc(int c) {
    return fputc(c, fp);
}

int EbrFputc(int c, EbrFile* fp) {
    return fp->Putc(c);
}

int EbrIOFile::Rewind() {
    rewind(fp);

    return 0;
}

int EbrRewind(EbrFile* fp) {
    fp->Rewind();

    return 0;
}

int EbrIOFile::Error() {
    return ferror(fp);
}

int EbrFerror(EbrFile* fp) {
    return fp->Error();
}

int EbrIOFile::Getc() {
    return fgetc(fp);
}

int EbrFgetc(EbrFile* fp) {
    return fp->Getc();
}

int EbrIOFile::Ungetc(int val) {
    return ungetc(val, fp);
}

int EbrUngetc(int val, EbrFile* fp) {
    return fp->Ungetc(val);
}

char* EbrIOFile::Gets(char* dest, size_t size) {
    return fgets(dest, size, fp);
}

char* EbrFgets(char* dest, size_t size, EbrFile* fp) {
    return fp->Gets(dest, size);
}

int EbrIOFile::Puts(const char* str) {
    return fputs(str, fp);
}

int EbrFputs(const char* str, EbrFile* fp) {
    return fp->Puts(str);
}

int EbrFileno(EbrFile* fp) {
    return fp->idx;
}

FILE* EbrNativeFILE(EbrFile* fp) {
    return ((EbrIOFile*)fp)->fp;
}

void EbrIOFile::Clearerr() {
    return clearerr(fp);
}

void EbrClearerr(EbrFile* fp) {
    return fp->Clearerr();
}

EbrFile* EbrFreopen(const char* filename, const char* mode, EbrFile* cur) {
    FILE* fp = NULL;

    freopen_s(&fp, CPathMapper(filename), mode, ((EbrIOFile*)cur)->fp);
    if (!fp)
        return NULL;

    EbrIOFile* ret = new EbrIOFile();
    ret->fp = fp;
    ret->filefd = _fileno(fp);

    return EbrAllocFile(ret);
}

int EbrIOFile::Flush() {
    return fflush(fp);
}

int EbrFflush(EbrFile* fp) {
    return fp->Flush();
}

int EbrIOFile::Setpos(__int64* pos) {
    return fsetpos(fp, pos);
}

int EbrFsetpos(EbrFile* fp, __int64* pos) {
    return fp->Setpos(pos);
}

int EbrIOFile::Getpos(__int64* pos) {
    return fgetpos(fp, pos);
}

int EbrFgetpos(EbrFile* fp, __int64* pos) {
    return fp->Getpos(pos);
}

int EbrIOFile::Dup() {
    int newHandle = _dup(filefd);
    EbrIOFile* newFile = new EbrIOFile();
    newFile->filefd = newHandle;
    EbrFile* ret = EbrAllocFile(newFile);

    return ret->idx;
}

int EbrDup(int fd) {
    return _openFiles[fd]->Dup();
}

int EbrClose(int fd) {
    EbrFile* file = _openFiles[fd];
    int ret = file->Close();
    EbrFreeFile(file);
    return ret;
}

int EbrFd2Host(int fd) {
    return _openFiles[fd]->HostFd();
}

int EbrIOFile::Stat(struct stat* ret) {
    return fstat(filefd, ret);
}

int EbrFstat(int fd, struct stat* ret) {
    return _openFiles[fd]->Stat(ret);
}

int EbrIOFile::Read(void* dest, size_t count) {
    return _read(filefd, dest, count);
}

int EbrRead(int fd, void* dest, size_t count) {
    return _openFiles[fd]->Read(dest, count);
}

int EbrIOFile::Write(const void* src, size_t count) {
    return _write(filefd, src, count);
}

int EbrWrite(int fd, const void* src, size_t count) {
    return _openFiles[fd]->Write(src, count);
}

int EbrIOFile::Lseek(__int64 pos, int whence) {
    return _lseeki64(filefd, pos, whence);
}

int EbrLseek(int fd, __int64 pos, int whence) {
    return _openFiles[fd]->Lseek(pos, whence);
}

int EbrIOFile::Truncate(off_t size) {
    return _chsize(filefd, size);
}

int EbrTruncate(int fd, off_t size) {
    return _openFiles[fd]->Truncate(size);
}

int EbrIOFile::Truncate64(__int64 size) {
    return _chsize_s(filefd, size);
}

int EbrTruncate64(int fd, __int64 size) {
    return _openFiles[fd]->Truncate64(size);
}

typedef struct {
    int fd;
    int size;
} MapInfo;

static std::map<void*, MapInfo> _memoryMaps;

bool EbrRemoveEmptyDir(const char* path) {
    return RemoveDirectoryA(CPathMapper(path));
}

bool EbrRename(const char* path1, const char* path2) {
    return rename(CPathMapper(path1), CPathMapper(path2)) == 0;
}

bool EbrUnlink(const char* path) {
    return _unlink(CPathMapper(path)) == 0;
}

__int64 startTime;

double EbrGetMediaTime() {
    unsigned __int64 curTime, curFreq;

    double ret;

    do {
        BOOL success = QueryPerformanceCounter((LARGE_INTEGER*)&curTime);
        assert(success == TRUE);
        success = QueryPerformanceFrequency((LARGE_INTEGER*)&curFreq);
        assert(success == TRUE);

        // curFreq *= 2;

        if (startTime == 0) {
            startTime = curTime;
        }
        curTime -= startTime;

        ret = ((double)curTime) / ((double)curFreq);
    } while (ret != ret); //  avoids QNAN

    return ret;
}

extern "C" int EbrAssert(const char* expr, const char* file, int line) {
    printf("Assertion %s:%d: %s\n", file, line, expr);
    return 0;
}

#define FSROOT "."
#define mkdir _mkdir
char g_WritableFolder[2048] = ".";

void EbrSetWritableFolder(const char* folder) {
    strcpy_s(g_WritableFolder, folder);
}

const char* EbrGetWritableFolder() {
    return g_WritableFolder;
}

bool EbrGetRootMapping(const char* dirName, char* dirOut, uint32_t maxLen) {
    if (dirName == NULL) {
        strcpy_s(dirOut, maxLen, FSROOT);
        return true;
    }
    if (_stricmp(dirName, "Documents") == 0) {
        sprintf_s(dirOut, maxLen, "%s\\Documents", g_WritableFolder);
        mkdir(dirOut);

        char tmpDir[4096];
        strcpy_s(tmpDir, dirOut);
        strcat_s(tmpDir, "\\Library");
        mkdir(tmpDir);
        return true;
    }
    if (_stricmp(dirName, "Cache") == 0) {
        sprintf_s(dirOut, maxLen, "%s\\cache", g_WritableFolder);
        mkdir(dirOut);
        return true;
    }
    if (_stricmp(dirName, "Library") == 0) {
        sprintf_s(dirOut, maxLen, "%s\\Library", g_WritableFolder);
        mkdir(dirOut);
        return true;
    }
    if (_stricmp(dirName, "AppSupport") == 0) {
        sprintf_s(dirOut, maxLen, "%s\\AppSupport", g_WritableFolder);
        mkdir(dirOut);
        return true;
    }
    if (_stricmp(dirName, "tmp") == 0) {
        sprintf_s(dirOut, maxLen, "%s\\tmp", g_WritableFolder);
        mkdir(dirOut);
        return true;
    }
    if (_stricmp(dirName, "shared") == 0) {
        sprintf_s(dirOut, maxLen, "%s\\shared", g_WritableFolder);
        mkdir(dirOut);
        return true;
    }
    static std::regex drive("[a-zA-Z]:");
    if (std::regex_match(dirName, drive)) {
        sprintf_s(dirOut, maxLen, dirName);
        return true;
    }
    sprintf_s(dirOut, maxLen, FSROOT "\\%s", dirName);
    return true;
}

bool EbrMkdir(const char* path) {
    return _mkdir(CPathMapper(path)) == 0;
}

char* EbrGetcwd(char* buf, size_t len) {
    strncpy_s(buf, len, CPathMapper::currentDir, len);
    return buf;
}

int EbrChdir(const char* path) {
    CPathMapper::setCWD(path);

    return 0;
}

void dbg_printf(const char* fmt, ...) {
#ifdef _DEBUG
    va_list va;

    va_start(va, fmt);
    char buf[4096];
    vsnprintf_s(buf, sizeof(buf), 4095, fmt, va);
    va_end(va);
    buf[4095] = 0;
    OutputDebugStringA(buf);
#endif
}

#define PATH_SEPARATOR "/"

bool EbrRemove(const char* path) {
    struct stat s;
    if (EbrStat(path, &s) == 0) {
        if (s.st_mode & S_IFREG) {
            if (EbrUnlink(path)) {
                return true;
            } else {
                TraceError(TAG, L"Failed to unlink file %hs", path);
                return false;
            }
        } else if (s.st_mode & S_IFDIR) {
            EbrDir* dir = EbrOpenDir(path);
            if (dir) {
                EbrDirEnt ent;
                while (EbrReadDir(dir, &ent)) {
                    if (strcmp(ent.fileName, ".") == 0 || strcmp(ent.fileName, "..") == 0)
                        continue;

                    char fullPath[4096]; // max path?
                    sprintf_s(fullPath, sizeof(fullPath), "%s%s%s", path, PATH_SEPARATOR, ent.fileName);
                    if (!EbrRemove(fullPath)) {
                        EbrCloseDir(dir);
                        return false;
                    }
                }
                EbrCloseDir(dir);
            }

            return EbrRemoveEmptyDir(path);
        } else {
            TraceVerbose(TAG, L"Unrecognized file type: %d", s.st_mode);
            return false;
        }
    }
    return false;
}
