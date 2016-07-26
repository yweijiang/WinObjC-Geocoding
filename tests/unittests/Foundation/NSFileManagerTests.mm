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

#import <sys/types.h>
#import <sys/stat.h>
#import <TestFramework.h>
#import <time.h>
#import <stdio.h>
#import <errno.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSNumber.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSURL.h>
#import <stdlib.h>
#import <windows.h>
#import <Starboard/SmartTypes.h>

static NSString* getModulePath() {
    char fullPath[_MAX_PATH];
    GetModuleFileNameA(NULL, fullPath, _MAX_PATH);
    return [@(fullPath) stringByDeletingLastPathComponent];
}

static NSString* getPathToFile(NSString* fileName) {
    static StrongId<NSString*> refPath = getModulePath();
    return [refPath stringByAppendingPathComponent:fileName];
}

static void createFileWithContentAndVerify(NSString* fileName, NSString* content) {
    NSString* fullPath = getPathToFile(fileName);
    NSError* error = nil;
    ASSERT_TRUE([content writeToFile:fullPath atomically:NO encoding:NSUTF8StringEncoding error:&error]);
    ASSERT_EQ(nil, error);
    ASSERT_TRUE([[NSFileManager defaultManager] fileExistsAtPath:fullPath]);
}

void deleteFile(NSString* name) {
    NSString* fullPath = getPathToFile(name);
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
    }
};

using unique_fileDeleter = std::unique_ptr<NSString, decltype(&deleteFile)>;

TEST(NSFileManager, GetAttributes) {
    // get test startup full path
    wchar_t fullPath[_MAX_PATH];
    GetModuleFileNameW(NULL, fullPath, _MAX_PATH);

    // split test startup full path into components like drive, directory, filename and ext etc.
    wchar_t drive[_MAX_DRIVE];
    wchar_t dir[_MAX_DIR];
    ASSERT_TRUE(::_wsplitpath_s(fullPath, drive, _countof(drive), dir, _countof(dir), NULL, 0, NULL, 0) == 0);

    // reconstruct fullpath for test artifact file. e.g., C:\WinObjc\WinObjC\build\Debug\data\NSFileManagerUT.txt
    ASSERT_TRUE(wcscat_s(dir, _countof(dir), L"\\data\\") == 0);
    ASSERT_TRUE(::_wmakepath_s(fullPath, _countof(fullPath), drive, dir, L"NSFileManagerUT", L".txt") == 0);
    NSString* testFileFullPath = [NSString stringWithCharacters:(const unichar*)fullPath length:_MAX_PATH];

    LOG_INFO("this test try to validate file creation date and modification date and size for %@", testFileFullPath);
    NSFileManager* manager = [NSFileManager defaultManager];
    ASSERT_TRUE_MSG([manager fileExistsAtPath:testFileFullPath], "Failed: file %@ does not exist", testFileFullPath);

    NSDictionary* attributes = [manager fileAttributesAtPath:testFileFullPath traverseLink:YES];
    ASSERT_TRUE_MSG(attributes != nil, "failed to get file attributes for %@", testFileFullPath);

    // get file attributes from windows side
    struct _stat fileStatus = { 0 };
    ASSERT_TRUE(::_wstat(fullPath, &fileStatus) == 0);

    // check file creation date
    NSDate* expectedCreationDate = [NSDate dateWithTimeIntervalSince1970:(double)fileStatus.st_ctime];
    NSDate* creationDate = [attributes fileCreationDate];
    ASSERT_TRUE_MSG(creationDate != nil, "failed to get creation date for %@", testFileFullPath);
    ASSERT_OBJCEQ_MSG(expectedCreationDate, creationDate, "failed to check creation date for %@", testFileFullPath);

    // check file modification date
    NSDate* expectedModificationDate = [NSDate dateWithTimeIntervalSince1970:fileStatus.st_mtime];
    NSDate* modificationDate = [attributes fileModificationDate];
    ASSERT_TRUE_MSG(modificationDate != nil, "failed to get ModificationDate for %@", testFileFullPath);
    ASSERT_OBJCEQ_MSG(expectedModificationDate, modificationDate, "failed to check modification date for %@", testFileFullPath);

    // now check file size
    ASSERT_TRUE_MSG(fileStatus.st_size == static_cast<long>([attributes fileSize]), "failed to check file size for %@", testFileFullPath);
}

TEST(NSFileManager, EnumateDirectoryUsingURL) {
    // get test startup full path
    wchar_t startUpPath[_MAX_PATH];
    GetModuleFileNameW(NULL, startUpPath, _MAX_PATH);

    // construct the start up dir
    wchar_t drive[_MAX_DRIVE];
    wchar_t dir[_MAX_DIR];
    ASSERT_TRUE(::_wsplitpath_s(startUpPath, drive, _countof(drive), dir, _countof(dir), NULL, 0, NULL, 0) == 0);
    ASSERT_TRUE(::_wmakepath_s(startUpPath, _countof(startUpPath), drive, dir, L"", L"") == 0);

    // change current dir to app start up path
    ASSERT_TRUE(SetCurrentDirectoryW(startUpPath) != 0);
    wchar_t currentDir[_MAX_PATH];
    DWORD ret = GetCurrentDirectoryW(_MAX_PATH, currentDir);
    ASSERT_TRUE(ret > 0 && ret < _MAX_PATH);
    LOG_INFO("Change current dir to:%@", [NSString stringWithCharacters:(const unichar*)currentDir length:_MAX_PATH]);

    // construct target URL using current directory and relative URL
    NSFileManager* manager = [NSFileManager defaultManager];
    NSURL* baseURL = [NSURL fileURLWithPath:[manager currentDirectoryPath]];
    NSURL* targetURL = [NSURL URLWithString:@"data/" relativeToURL:baseURL];

    // enumerate target URL
    NSArray* urlContents = [manager contentsOfDirectoryAtURL:targetURL
                                  includingPropertiesForKeys:[NSArray arrayWithObject:NSURLContentModificationDateKey]
                                                     options:(NSDirectoryEnumerationOptions)0
                                                       error:nullptr];

    // verify only one file exists
    const NSString* c_expectedFileName = @"NSFileManagerUT.txt";
    ASSERT_TRUE_MSG([urlContents count] == 1, "Should have one file named %@", c_expectedFileName);

    // break file URL into comopnents, get last object of it - which is the file name, and verify name is the expected
    NSURL* targetFileURL = [urlContents firstObject];
    NSString* acutalFileName = [[targetFileURL pathComponents] lastObject];
    ASSERT_OBJCEQ_MSG(c_expectedFileName, acutalFileName, "FileName isn't the same");

    // construct file path for target file and get its attrbutes from windows side
    wchar_t targetFileFullPath[_MAX_PATH];
    ASSERT_TRUE(wcscpy_s(targetFileFullPath, _countof(targetFileFullPath), currentDir) == 0);
    ASSERT_TRUE(wcscat_s(targetFileFullPath, _countof(targetFileFullPath), L"\\data\\NSFileManagerUT.txt") == 0);
    struct _stat fileStatus = { 0 };
    ASSERT_TRUE(::_wstat(targetFileFullPath, &fileStatus) == 0);

    // TODO: 7491194: Implement CFURL resourceValue APIs
    // check NSURL resourceValue of NSURLContentModificationDateKey is the same as file modification date
    // NSDate* expectedModificationDate = [NSDate dateWithTimeIntervalSince1970:fileStatus.st_mtime];
    // id value;
    // [targetFileURL getResourceValue:&value forKey:NSURLContentModificationDateKey error:nil];
    // NSDate* actualModificationDate = static_cast<NSDate*>(value);
    // ASSERT_TRUE_MSG(actualModificationDate != nil, "failed to get ModificationDate from %@", targetFileURL);
    // ASSERT_OBJCEQ_MSG(expectedModificationDate, actualModificationDate, "failed to check modification date for %@", targetFileURL);
}

TEST(NSFileManager, ChangeDirectory) {
    NSFileManager* manager = [NSFileManager defaultManager];
    NSString* originalPath = [manager currentDirectoryPath];

    NSString* parentPath = [[[NSURL fileURLWithPath:originalPath] URLByDeletingLastPathComponent] path];
    ASSERT_TRUE([manager changeCurrentDirectoryPath:parentPath]);

    NSString* currentPath = [manager currentDirectoryPath];
    ASSERT_OBJCNE_MSG(originalPath, currentPath, "Expected change in current directory");
    ASSERT_OBJCEQ_MSG(parentPath, currentPath, "Expected current directory to change to parentPath");
}

TEST(NSFileManager, MoveFileViaPath) {
    unique_fileDeleter srcName(@"NSFileManagerMoveTestFilePath.txt", deleteFile);
    unique_fileDeleter destName(@"MovedFilePath.txt", deleteFile);

    NSString* content = @"The Quick Brown Fox.";
    createFileWithContentAndVerify(srcName.get(), content);

    NSString* srcPath = getPathToFile(srcName.get());
    NSString* destPath = getPathToFile(destName.get());

    NSFileManager* manager = [NSFileManager defaultManager];

    NSError* error = nil;
    BOOL status = [manager moveItemAtPath:srcPath toPath:destPath error:&error];
    ASSERT_TRUE(status);
    EXPECT_EQ(nil, error);

    // Verify file exists.
    ASSERT_TRUE([manager fileExistsAtPath:destPath]);
    EXPECT_FALSE([manager fileExistsAtPath:srcPath]);

    // Verify data.
    ASSERT_OBJCEQ([content dataUsingEncoding:NSUTF8StringEncoding], [NSData dataWithContentsOfFile:destPath]);
}

TEST(NSFileManager, MoveFileViaURL) {
    unique_fileDeleter srcName(@"NSFileManagerMoveTestFileURL.txt", deleteFile);
    unique_fileDeleter destName(@"MovedFileURL.txt", deleteFile);

    NSString* content = @"The Quick Brown Fox.";
    createFileWithContentAndVerify(srcName.get(), content);

    NSURL* srcURL = [NSURL fileURLWithPath:getPathToFile(srcName.get())];
    NSURL* destURL = [NSURL fileURLWithPath:getPathToFile(destName.get())];

    NSFileManager* manager = [NSFileManager defaultManager];

    NSError* error = nil;
    BOOL status = [manager moveItemAtURL:srcURL toURL:destURL error:&error];
    ASSERT_TRUE(status);
    EXPECT_EQ(nil, error);

    // Verify file exists.
    ASSERT_TRUE([manager fileExistsAtPath:[destURL path]]);
    EXPECT_FALSE([manager fileExistsAtPath:[srcURL path]]);

    // Verify data.
    ASSERT_OBJCEQ([content dataUsingEncoding:NSUTF8StringEncoding], [NSData dataWithContentsOfURL:destURL]);
}
