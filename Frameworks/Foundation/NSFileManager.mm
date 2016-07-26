//******************************************************************************
//
// Copyright (c) Microsoft. All rights reserved.
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

#import <Starboard.h>
#import <StubReturn.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSError.h>
#import <Foundation/NSString.h>
#import <Foundation/NSMutableArray.h>
#import <Foundation/NSMutableDictionary.h>
#import <Foundation/NSNumber.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSData.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSDirectoryEnumerator.h>
#import <Foundation/NSDictionary.h>
#import <string>
#import <vector>
#import <sys/stat.h>
#import <errno.h>
#import <LoggingNative.h>
#import <CFFoundationInternal.h>
#import <ForFoundationOnly.h>
#import "NSDirectoryEnumeratorInternal.h"

static const wchar_t* TAG = L"NSFileManager";

#ifdef __linux__
#define _S_IFDIR S_IFDIR
#endif

// file attribute keys
NSString* const NSFileType = @"NSFileType";
NSString* const NSFileSize = @"NSFileSize";
NSString* const NSFileModificationDate = @"NSFileModificationDate";
NSString* const NSFileReferenceCount = @"NSFileReferenceCount";
NSString* const NSFileDeviceIdentifier = @"NSFileDeviceIdentifier";
NSString* const NSFileOwnerAccountName = @"NSFileOwnerAccountName";
NSString* const NSFileGroupOwnerAccountName = @"NSFileGroupOwnerAccountName";
NSString* const NSFilePosixPermissions = @"NSFilePosixPermissions";
NSString* const NSFileSystemNumber = @"NSFileSystemNumber";
NSString* const NSFileSystemFileNumber = @"NSFileSystemFileNumber";
NSString* const NSFileExtensionHidden = @"NSFileExtensionHidden";
NSString* const NSFileHFSCreatorCode = @"NSFileHFSCreatorCode";
NSString* const NSFileHFSTypeCode = @"NSFileHFSTypeCode";
NSString* const NSFileImmutable = @"NSFileImmutable";
NSString* const NSFileAppendOnly = @"NSFileAppendOnly";
NSString* const NSFileCreationDate = @"NSFileCreationDate";
NSString* const NSFileOwnerAccountID = @"NSFileOwnerAccountID";
NSString* const NSFileGroupOwnerAccountID = @"NSFileGroupOwnerAccountID";
NSString* const NSFileBusy = @"NSFileBusy";

NSString* const NSFileProtectionKey = @"NSFileProtectionKey";

// NSFileType Attribute Values
NSString* const NSFileTypeDirectory = @"NSFileTypeDirectory";
NSString* const NSFileTypeRegular = @"NSFileTypeRegular";
NSString* const NSFileTypeSymbolicLink = @"NSFileTypeSymbolicLink";
NSString* const NSFileTypeSocket = @"NSFileTypeSocket";
NSString* const NSFileTypeCharacterSpecial = @"NSFileTypeCharacterSpecial";
NSString* const NSFileTypeBlockSpecial = @"NSFileTypeBlockSpecial";
NSString* const NSFileTypeUnknown = @"NSFileTypeUnknown";

// File-System attribute Keys
NSString* const NSFileSystemSize = @"NSFileSystemSize";
NSString* const NSFileSystemFreeSize = @"NSFileSystemFreeSize";
NSString* const NSFileSystemNodes = @"NSFileSystemNodes";
NSString* const NSFileSystemFreeNodes = @"NSFileSystemFreeNodes";

// File Protection Values
NSString* const NSFileProtectionNone = @"NSFileProtectionNone";
NSString* const NSFileProtectionComplete = @"NSFileProtectionComplete";
NSString* const NSFileProtectionCompleteUnlessOpen = @"NSFileProtectionCompleteUnlessOpen";
NSString* const NSFileProtectionCompleteUntilFirstUserAuthentication = @"NSFileProtectionCompleteUntilFirstUserAuthentication";

@implementation NSFileManager

// Creating a File Manager

/**
 @Status Interoperable
*/
+ (NSFileManager*)defaultManager {
    static id defaultManager = [[self alloc] init];

    return defaultManager;
}

// Locating System Directories

/**
 @Status Caveat
 @Notes Ignores appropriateForURL, create, and error. Calls URLsForDirectory and returns first result.
*/
- (NSURL*)URLForDirectory:(NSSearchPathDirectory)directory
                 inDomain:(NSSearchPathDomainMask)domains
        appropriateForURL:(NSURL*)forURL
                   create:(BOOL)create
                    error:(NSError**)error {
    NSArray* urls = [self URLsForDirectory:directory inDomains:domains];
    if ([urls count] > 0) {
        return [urls objectAtIndex:0];
    }

    return nil;
}

/**
 @Status Interoperable
*/
- (NSArray*)URLsForDirectory:(NSSearchPathDirectory)directory inDomains:(NSSearchPathDomainMask)domains {
    id paths = NSSearchPathForDirectoriesInDomains(directory, domains, YES);

    int count = [paths count];

    id ret = [NSMutableArray array];

    for (int i = 0; i < count; i++) {
        id curObj = [paths objectAtIndex:i];

        id newUrl = [NSURL fileURLWithPath:curObj];

        [ret addObject:newUrl];
    }

    return ret;
}

// Locating Application Group Container Directories

/**
 @Status Stub
*/
- (NSURL*)containerURLForSecurityApplicationGroupIdentifier:(NSString*)groupIdentifier {
    UNIMPLEMENTED();
    return nil;
}

// Discovering Directory Contents

/**
 @Status Caveat
 @Notes Fetching directory contents, return an array of NSURL objects. Currently ignoring passed in mask
   and only support prefecch NSURLContentModificationDateKey
*/
- (NSArray*)contentsOfDirectoryAtURL:(NSURL*)url
          includingPropertiesForKeys:(NSArray*)keys
                             options:(NSDirectoryEnumerationOptions)mask
                               error:(NSError**)error {
    if (error) {
        *error = nil;
    }

    // check existence of target dir
    auto isDir = NO;
    if (![self fileExistsAtPath:url.path isDirectory:&isDir]) {
        if (error) {
            // TODO: standardize the error code and message
            *error = [NSError errorWithDomain:@"Target path does not exist" code:100 userInfo:nil];
        }
        return nil;
    } else if (!isDir) {
        // TODO: standardize the error code and message
        if (error) {
            *error = [NSError errorWithDomain:@"Target Path is not a directory" code:100 userInfo:nil];
        }
        return nil;
    }

    id enumerator = [[NSDirectoryEnumerator alloc] _initWithPath:[[url path] UTF8String]
                                                         shallow:YES
                                      includingPropertiesForKeys:keys
                                                         options:mask
                                                     returnNSURL:YES];

    // by enumerating the directory, construct the direcotry contents at this URL
    id ret = [enumerator allObjects];
    [enumerator release];
    return ret;
}

/**
 @Status Caveat
 @Notes Path must exist
*/
- (NSArray*)contentsOfDirectoryAtPath:(NSString*)pathAddr error:(NSError**)error {
    id enumerator = [NSDirectoryEnumerator new];
    enumerator = [enumerator _initWithPath:[pathAddr UTF8String]
                                   shallow:YES
                includingPropertiesForKeys:nil
                                   options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                               returnNSURL:NO];

    id ret = [enumerator allObjects];
    [enumerator release];
    return ret;
}

/**
 @Status Stub
*/
- (NSDirectoryEnumerator*)enumeratorAtURL:(NSURL*)url
               includingPropertiesForKeys:(NSArray*)keys
                                  options:(NSDirectoryEnumerationOptions)mask
                             errorHandler:(BOOL (^)(NSURL* url, NSError* error))handler {
    UNIMPLEMENTED();
    return nil;
}

/**
 @Status Interoperable
*/
- (id)enumeratorAtPath:(id)pathAddr {
    const char* path = [pathAddr UTF8String];

    NSDirectoryEnumerator* directoryEnum = [NSDirectoryEnumerator new];
    [directoryEnum _initWithPath:path
                           shallow:NO
        includingPropertiesForKeys:nil
                           options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                       returnNSURL:NO];

    return directoryEnum;
}

/**
 @Status Stub
*/
- (NSArray*)mountedVolumeURLsIncludingResourceValuesForKeys:(NSArray*)propertyKeys options:(NSVolumeEnumerationOptions)options {
    UNIMPLEMENTED();
    return nil;
}

/**
 @Status Stub
*/
- (NSArray*)subpathsOfDirectoryAtPath:(NSString*)path error:(NSError**)error {
    UNIMPLEMENTED();
    return nil;
}

/**
 @Status Stub
*/
- (NSArray*)subpathsAtPath:(NSString*)path {
    UNIMPLEMENTED();
    return nil;
}

// Creating and Deleting Items

/**
 @Status Caveat
 @Notes attributes parameter not supported. error parameter not supported.
*/
- (BOOL)createDirectoryAtURL:(NSURL*)url
 withIntermediateDirectories:(BOOL)createIntermediates
                  attributes:(NSDictionary*)attrs
                       error:(NSError**)err {
    id path = [url path];

    return [self createDirectoryAtPath:path withIntermediateDirectories:createIntermediates attributes:attrs error:err];
}

/**
 @Status Caveat
 @Notes attributes parameter not supported.  error parameter is not populated
*/
- (BOOL)createDirectoryAtPath:(NSString*)pathAddr
  withIntermediateDirectories:(BOOL)createIntermediates
                   attributes:(NSDictionary*)attrs
                        error:(NSError**)err {
    if (createIntermediates) {
        const char* path = [pathAddr UTF8String];
        id components = [pathAddr pathComponents];
        char curPath[256] = "";

        int count = [components count];
        for (int i = 0; i < count; i++) {
            id curComponent = [components objectAtIndex:i];
            const char* pComponent = [curComponent UTF8String];

            if (strlen(pComponent) > 0) {
                strcat_s(curPath, _countof(curPath), pComponent);
                strcat_s(curPath, _countof(curPath), "/");
            }

            if (strlen(curPath) > 0) {
                bool success = EbrMkdir(curPath);
                if (!success && errno != EEXIST) {
                    TraceError(TAG, L"Failed to make path %hs: %d", curPath, errno);
                    // return NO;
                }
            }
        }

        return YES;
    } else {
        const char* path = [pathAddr UTF8String];
        if (EbrMkdir(path) == 0) {
            return YES;
        } else {
            return NO;
        }
    }
}

/**
 @Status Caveat
 @Notes attributes parameter not supported
*/
- (BOOL)createFileAtPath:(id)pathAddr contents:(id)contents attributes:(id)attributes {
    const char* path = [pathAddr UTF8String];

    TraceVerbose(TAG, L"createFileAtPath: %hs", path);

    EbrFile* fpOut = EbrFopen(path, "wb");

    if (!fpOut) {
        TraceError(TAG, L"failed to createFileAtPath: %hs", path);
        return NO;
    }

    char* bytes = (char*)[contents bytes];
    int length = [contents length];

    EbrFwrite(bytes, 1, length, fpOut);

    EbrFclose(fpOut);

    return YES;
}

/**
 @Status Interoperable
*/
- (BOOL)removeItemAtURL:(NSURL*)URL error:(NSError**)error {
    id pathAddr = [URL path];
    if (pathAddr == nil) {
        TraceVerbose(TAG, L"removeItemAtURL: nil!");
        return YES;
    }

    return [self removeItemAtPath:pathAddr error:error];
}

/**
 @Status Stub
*/
- (BOOL)replaceItemAtURL:(NSURL*)originalItemURL
           withItemAtURL:(NSURL*)newItemURL
          backupItemName:(NSString*)backupItemName
                 options:(NSFileManagerItemReplacementOptions)options
        resultingItemURL:(NSURL**)resultingURL
                   error:(NSError**)error {
    UNIMPLEMENTED();
    return NO;
}

/**
 @Status Stub
*/
- (BOOL)trashItemAtURL:(NSURL*)url resultingItemURL:(NSURL**)outResultingURL error:(NSError**)error {
    UNIMPLEMENTED();
    return NO;
}

// Moving and Copying Items

/**
 @Status Stub
*/
- (BOOL)copyItemAtURL:(NSURL*)srcURL toURL:(NSURL*)dstURL error:(NSError**)error {
    UNIMPLEMENTED();

    return NO;
}

/**
 @Status Interoperable
*/
- (BOOL)copyItemAtPath:(id)srcPath toPath:(id)destPath error:(NSError**)error {
    if (srcPath == nil || destPath == nil) {
        TraceVerbose(TAG, L"copyItemAtPath: nil!");
        return NO;
    }

    const char* src = [srcPath UTF8String];
    const char* dest = [destPath UTF8String];

    if (EbrAccess(dest, 0) == 0) {
        if (error) {
            // TODO: standardize the error code and message
            *error = [NSError errorWithDomain:@"Would overwrite destination" code:100 userInfo:nil];
        }
        TraceVerbose(TAG, L"Not copying %hs to %hs because dest exists", src, dest);
        return NO;
    }

    TraceVerbose(TAG, L"Copying %hs to %hs", src, dest);

    EbrFile* fpIn = EbrFopen(src, "rb");
    if (!fpIn) {
        TraceError(TAG, L"Error opening %hs", src);
        return NO;
    }

    EbrFile* fpOut = EbrFopen(dest, "wb");
    if (!fpOut) {
        EbrFclose(fpIn);
        TraceError(TAG, L"Error opening %hs", dest);
        return NO;
    }

    while (!EbrFeof(fpIn)) {
        BYTE in[4096];
        int read = EbrFread(in, 1, 4096, fpIn);
        EbrFwrite(in, 1, read, fpOut);
    }

    EbrFclose(fpOut);
    EbrFclose(fpIn);

    TraceVerbose(TAG, L"Done copying");

    return YES;
}

/**
 @Status Caveat
 @Notes does not support file manager move delegates for shouldMoveItem or shouldProceedAfterError.
*/
- (BOOL)moveItemAtURL:(NSURL*)srcURL toURL:(NSURL*)dstURL error:(NSError**)error {
    THROW_NS_IF_FALSE(E_INVALIDARG, srcURL != nil);
    THROW_NS_IF_FALSE(E_INVALIDARG, dstURL != nil);
    if (![srcURL isFileURL] || ![dstURL isFileURL]) {
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnsupportedSchemeError userInfo:nil];
        }

        return NO;
    }
    return [self moveItemAtPath:[srcURL path] toPath:[dstURL path] error:error];
}

/**
 @Status Caveat
 @Notes does not support file manager move delegates for shouldMoveItem or shouldProceedAfterError.
*/
- (BOOL)moveItemAtPath:(NSString*)srcPath toPath:(NSString*)destPath error:(NSError**)error {
    THROW_NS_IF_FALSE(E_INVALIDARG, srcPath != nil);
    THROW_NS_IF_FALSE(E_INVALIDARG, destPath != nil);

    if (![self fileExistsAtPath:srcPath]) {
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:nil];
        }

        return NO;
    }

    const char* src = [srcPath UTF8String];
    const char* dest = [destPath UTF8String];

    bool success = EbrRename(src, dest);
    if (!success) {
        TraceError(TAG, L"Rename failed. errno:%d", errno);
        if (error) {
            *error = [NSError errorWithDomain:NSWin32ErrorDomain code:errno userInfo:nil];
        }
        return NO;
    }

    return YES;
}

// Managing iCloud-Based Items

/**
 @Status Stub
*/
- (NSURL*)URLForUbiquityContainerIdentifier:(NSString*)containerID {
    UNIMPLEMENTED();

    return nil;
}

/**
 @Status Stub
*/
- (BOOL)isUbiquitousItemAtURL:(NSURL*)url {
    UNIMPLEMENTED();
    return NO;
}

/**
 @Status Stub
*/
- (BOOL)setUbiquitous:(BOOL)flag itemAtURL:(NSURL*)url destinationURL:(NSURL*)destinationURL error:(NSError**)errorOut {
    UNIMPLEMENTED();
    return NO;
}

/**
 @Status Stub
*/
- (BOOL)startDownloadingUbiquitousItemAtURL:(NSURL*)url error:(NSError**)errorOut {
    UNIMPLEMENTED();
    return NO;
}

/**
 @Status Stub
*/
- (BOOL)evictUbiquitousItemAtURL:(NSURL*)url error:(NSError**)errorOut {
    UNIMPLEMENTED();
    return NO;
}

/**
 @Status Stub
*/
- (NSURL*)URLForPublishingUbiquitousItemAtURL:(NSURL*)url expirationDate:(NSDate**)outDate error:(NSError**)error {
    UNIMPLEMENTED();
    return nil;
}

// Creating Symbolic and Hard Links
/**
 @Status Stub
*/
- (BOOL)createSymbolicLinkAtURL:(NSURL*)url withDestinationURL:(NSURL*)destURL error:(NSError**)error {
    UNIMPLEMENTED();
    return NO;
}

/**
 @Status Stub
*/
- (BOOL)createSymbolicLinkAtPath:(NSString*)path withDestinationPath:(NSString*)toPath error:(NSError**)error {
    UNIMPLEMENTED();
    return NO;
}

/**
 @Status Stub
*/
- (BOOL)linkItemAtURL:(NSURL*)srcURL toURL:(NSURL*)dstURL error:(NSError**)error {
    UNIMPLEMENTED();
    return NO;
}

/**
 @Status Stub
*/
- (BOOL)linkItemAtPath:(NSString*)fromPath toPath:(NSString*)toPath error:(NSError**)error {
    UNIMPLEMENTED();
    return NO;
}

/**
 @Status Caveat
 @Notes does not resolve symlinks
*/
- (NSString*)destinationOfSymbolicLinkAtPath:(NSString*)path error:(NSError* _Nullable*)error {
    return [[path copy] autorelease];
}

// Determining Access to Files

/**
 @Status Interoperable
*/
- (BOOL)fileExistsAtPath:(NSString*)pathAddr {
    if (pathAddr == nil) {
        return NO;
    }

    const char* path = [pathAddr UTF8String];

    if (strcmp(path, "") == 0) {
        return NO;
    }

    if (EbrAccess(path, 0) == 0) {
        return YES;
    } else {
        TraceVerbose(TAG, L"File @ %hs doesn't exist", path);
        return NO;
    }
}

/**
 @Status Interoperable
*/
- (BOOL)fileExistsAtPath:(NSString*)pathAddr isDirectory:(BOOL*)isDirectory {
    const char* path = [pathAddr UTF8String];
    struct stat st;

    if (EbrStat(path, &st) == 0) {
        if (isDirectory) {
            *isDirectory = (st.st_mode & _S_IFDIR) == _S_IFDIR;
        }
        return YES;
    } else {
        return NO;
    }
}

/**
 @Status Interoperable
*/
- (BOOL)isReadableFileAtPath:(id)pathAddr {
    const char* path = [pathAddr UTF8String];

    if (EbrAccess(path, 6) == 0) {
        return YES;
    } else {
        TraceVerbose(TAG, L"File @ %hs isn't writable", path);
        return NO;
    }
}

/**
 @Status Interoperable
*/
- (BOOL)isWritableFileAtPath:(id)pathAddr {
    const char* path = [pathAddr UTF8String];

    if (EbrAccess(path, 4) == 0) {
        return YES;
    } else {
        TraceVerbose(TAG, L"File @ %hs isn't readable", path);
        return NO;
    }
}

/**
 @Status Stub
*/
- (BOOL)isExecutableFileAtPath:(NSString*)path {
    UNIMPLEMENTED();
    return NO;
}

/**
 @Status Stub
*/
- (BOOL)isDeletableFileAtPath:(NSString*)path {
    UNIMPLEMENTED();
    return NO;
}

// Getting and Setting Attributes

/**
 @Status Stub
*/
- (NSArray*)componentsToDisplayForPath:(NSString*)path {
    UNIMPLEMENTED();
    return nil;
}

/**
 @Status Stub
*/
- (id)displayNameAtPath:(id)path {
    UNIMPLEMENTED();
    return path;
}

/**
 @Status Caveat
 @Notes Only NSFileSize and NSFileType attributes are supported
*/
- (id)attributesOfItemAtPath:(id)pathAddr error:(NSError**)error {
    if (pathAddr == nil) {
        TraceVerbose(TAG, L"attributesOfItemAtPath nil!");

        if (error) {
            // TODO: standardize the error code and message
            *error = [NSError errorWithDomain:@"Empty File Path" code:100 userInfo:nil];
        }

        return nil;
    }

    struct stat st;

    const char* path = [pathAddr UTF8String];
    TraceVerbose(TAG, L"attributesOfItemAtPath: %hs", path);

    if (EbrStat(path, &st) == -1) {
        if (error) {
            // TODO: standardize the error code and message
            *error = [NSError errorWithDomain:@"File not found" code:100 userInfo:nil];
        }
        return nil;
    }

    id ret = [NSMutableDictionary dictionary];

    [ret setValue:[NSNumber numberWithInt:st.st_size] forKey:NSFileSize];
    if (st.st_mode & _S_IFDIR) {
        [ret setValue:NSFileTypeDirectory forKey:NSFileType];
    } else {
        [ret setValue:NSFileTypeRegular forKey:NSFileType];
    }

    return ret;
}

/**
 @Status Stub
*/
- (id)attributesOfFileSystemForPath:(id)pathAddr error:(NSError**)error {
    UNIMPLEMENTED();
    if (error) {
        *error = nil;
    }

    const char* path = [pathAddr UTF8String];

    TraceVerbose(TAG, L"fileAttributesAtPath: %hs", path);

    id ret = [NSMutableDictionary dictionary];
    [ret setValue:[NSNumber numberWithInt:256 * 1024 * 1024] forKey:NSFileSystemFreeSize];

    return ret;
}

/**
 @Status Stub
*/
- (BOOL)setAttributes:(id)attribs ofItemAtPath:(id)pathAddr error:(NSError**)err {
    UNIMPLEMENTED();
    return YES;
}

// Getting and Comparing File Contents

/**
 @Status Interoperable
*/
- (id)contentsAtPath:(id)pathAddr {
    return [NSData dataWithContentsOfFile:pathAddr];
}

/**
 @Status Caveat
 @Notes Comparing directories not supported
*/
- (BOOL)contentsEqualAtPath:(id)pathObj1 andPath:(id)pathObj2 {
    const char* path1 = [pathObj1 UTF8String];
    const char* path2 = [pathObj2 UTF8String];

    bool dir = EbrIsDir(path1);
    if (dir != EbrIsDir(path2)) {
        return NO;
    }

    if (dir) {
        // no good:
        assert(0);
    } else {
        struct stat st1, st2;
        if (EbrStat(path1, &st1) != 0 || EbrStat(path2, &st2) != 0) {
            return NO;
        }

        if (st1.st_size != st2.st_size) {
            return NO;
        }

        id d1 = [[NSData alloc] initWithContentsOfFile:pathObj1];
        id d2 = [[NSData alloc] initWithContentsOfFile:pathObj2];

        bool ret = [d1 isEqualToData:d2] != 0;

        [d1 release];
        [d2 release];

        return ret;
    }

    return NO;
}

// Getting the Relationship Between Items

/**
 @Status Stub
*/
- (BOOL)getRelationship:(NSURLRelationship*)outRelationship
       ofDirectoryAtURL:(NSURL*)directoryURL
            toItemAtURL:(NSURL*)otherURL
                  error:(NSError**)error {
    UNIMPLEMENTED();
    return NO;
}

/**
 @Status Stub
*/
- (BOOL)getRelationship:(NSURLRelationship*)outRelationship
            ofDirectory:(NSSearchPathDirectory)directory
               inDomain:(NSSearchPathDomainMask)domainMask
            toItemAtURL:(NSURL*)url
                  error:(NSError**)error {
    UNIMPLEMENTED();
    return NO;
}

// Converting File Paths to Strings

/**
 @Status Stub
*/
- (const char*)fileSystemRepresentationWithPath:(id)pathAddr {
    UNIMPLEMENTED();
    return [pathAddr UTF8String];
}

/**
 @Status Stub
*/
- (id)stringWithFileSystemRepresentation:(const char*)path length:(NSUInteger)length {
    UNIMPLEMENTED();
    return [NSString stringWithCString:path length:length];
}

// Managing the Delegate

// Managing the Current Directory

/**
 @Status Interoperable
*/
- (BOOL)changeCurrentDirectoryPath:(NSString*)path {
    return (0 == _NS_chdir([path UTF8String]));
}

/**
 @Status Interoperable
*/
- (NSString*)currentDirectoryPath {
    return [[static_cast<NSURL*>(_CFURLCreateCurrentDirectoryURL(kCFAllocatorDefault)) autorelease] path];
}

// Deprecated Methods

/**
 @Status Stub
*/
- (BOOL)copyPath:(NSString*)src toPath:(NSString*)dest handler:handler {
    UNIMPLEMENTED();
    return NO;
}

/**
 @Status Stub
*/
- (BOOL)movePath:(NSString*)src toPath:(NSString*)dest handler:handler {
    UNIMPLEMENTED();
    return NO;
}

/**
 @Status Stub
*/
- (BOOL)removeFileAtPath:(NSString*)path handler:handler {
    UNIMPLEMENTED();
    return NO;
}

/**
 @Status Stub
*/
- (BOOL)changeFileAttributes:(NSDictionary*)attributes atPath:(NSString*)path {
    UNIMPLEMENTED();
    return NO;
}

/**
 @Status Caveat
 @Notes Only NSFileSize, NSFileType, NSFileCreationDate, NSFileModificationDate attributes are supported.
 @traverseLink not supported.
*/
- (NSDictionary*)fileAttributesAtPath:(NSString*)pathAddr traverseLink:(BOOL)traveseLinks {
    if (pathAddr == nil) {
        TraceVerbose(TAG, L"fileAttributesAtPath nil!");

        return nil;
    }

    struct stat st;

    const char* path = [pathAddr UTF8String];
    TraceVerbose(TAG, L"fileAttributesAtPath: %hs", path);

    if (EbrStat(path, &st) == -1) {
        return nil;
    }

    id ret = [NSMutableDictionary dictionary];

    [ret setValue:[NSNumber numberWithInt:st.st_size] forKey:NSFileSize];

    // NOTE: st_ctime is file creation time on windows for NTFS
    [ret setValue:[NSDate dateWithTimeIntervalSince1970:st.st_ctime] forKey:NSFileCreationDate];
    [ret setValue:[NSDate dateWithTimeIntervalSince1970:st.st_mtime] forKey:NSFileModificationDate];

    if (st.st_mode & _S_IFDIR) {
        [ret setValue:NSFileTypeDirectory forKey:NSFileType];
    } else {
        [ret setValue:NSFileTypeRegular forKey:NSFileType];
    }

    return ret;
}

/**
 @Status Caveat
 @Notes returns hardcoded attributes
*/
- (NSDictionary*)fileSystemAttributesAtPath:(NSString*)pathAddr {
    id ret = [NSMutableDictionary dictionary];
    [ret setValue:[NSNumber numberWithInt:32 * 1024 * 1024] forKey:NSFileSystemFreeSize];
    [ret setValue:[NSNumber numberWithInt:64 * 1024 * 1024 * 1024] forKey:NSFileSystemSize];

    return ret;
}

/**
 @Status Interoperable
*/
- (NSArray*)directoryContentsAtPath:(NSString*)pathAddr {
    id enumerator = [[[NSDirectoryEnumerator alloc] _initWithPath:[pathAddr UTF8String]
                                                          shallow:YES
                                       includingPropertiesForKeys:nil
                                                          options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                      returnNSURL:NO] autorelease];

    id ret = [enumerator allObjects];
    return ret;
}

/**
 @Status Caveat
 @Notes attributes parameter not supported
*/
- (BOOL)createDirectoryAtPath:(id)pathAddr attributes:(NSDictionary*)attrs {
    const char* path = [pathAddr UTF8String];

    if (EbrMkdir(path)) {
        return YES;
    } else {
        return NO;
    }
}

/**
 @Status Stub
*/
- (BOOL)createSymbolicLinkAtPath:(NSString*)path pathContent:(NSString*)destination {
    UNIMPLEMENTED();
    return NO;
}

/**
 @Status Stub
*/
- (NSString*)pathContentOfSymbolicLinkAtPath:(NSString*)path {
    UNIMPLEMENTED();
    return nil;
}

/**
 @Status Stub
*/
- (BOOL)linkPath:(NSString*)source toPath:(NSString*)destination handler:handler {
    UNIMPLEMENTED();
    return NO;
}

/**
 @Status Interoperable
*/
- (BOOL)removeItemAtPath:(id)pathAddr error:(NSError**)error {
    if (error) {
        *error = nil;
    }

    const char* path = [pathAddr UTF8String];
    TraceVerbose(TAG, L"removeItemAtPath: %hs", path);

    BOOL ret = EbrRemove(path);
    if (!ret && error) {
        // TODO: standardize the error code and message
        *error = [NSError errorWithDomain:@"Failed to delete file" code:100 userInfo:nil];
    }

    return ret;
}

@end

/**
 @Status Stub
 @Notes
*/
NSString* NSOpenStepRootDirectory() {
    UNIMPLEMENTED();
    return StubReturn();
}
