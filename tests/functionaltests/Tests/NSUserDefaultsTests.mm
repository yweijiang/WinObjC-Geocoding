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

#include <TestFramework.h>
#import <Foundation/Foundation.h>
#import <Corefoundation/CFBase.h>
#import <Corefoundation/CFPreferences.h>

TEST(NSUserDefaults, Basic) {
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    ASSERT_TRUE(userDefault != nil);

    NSString* key = @"testKey";

    // verify non file url is good
    NSURL* url1 = [[NSURL alloc] initWithString:@"http://www.test.com/"];
    [userDefault setURL:url1 forKey:key];

    NSURL* url2 = [userDefault URLForKey:key];
    ASSERT_OBJCEQ_MSG(url1, url2, "url should be equal");

    // verify file path url is good
    NSURL* url3 = [[NSURL alloc] initWithString:@"file://localhost/test1/test2/test3/"];
    [userDefault setURL:url3 forKey:key];

    NSURL* url4 = [userDefault URLForKey:key];
    ASSERT_OBJCEQ_MSG(url3, url4, "url should be equal");

    [url1 release];
    [url3 release];
}

TEST(NSUserDefaults, KVCArray) {
    [[NSUserDefaults standardUserDefaults] setObject:@[ @"User Preference 1" ] forKey:@"userPref1"];
    NSMutableArray* mutableSetting = [[NSUserDefaults standardUserDefaults] mutableArrayValueForKeyPath:@"userPref1"];
    EXPECT_OBJCNE(nil, mutableSetting);
    EXPECT_NO_THROW([mutableSetting addObject:@"Another"]);
    EXPECT_TRUE([[[NSUserDefaults standardUserDefaults] objectForKey:@"userPref1"] containsObject:@"Another"]);

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"nonexistentPreference"];
    mutableSetting = [[NSUserDefaults standardUserDefaults] mutableArrayValueForKeyPath:@"nonexistentPreference"];
    EXPECT_OBJCNE(nil, mutableSetting);
    EXPECT_NO_THROW([mutableSetting addObject:@"Another"]);
    EXPECT_TRUE([[[NSUserDefaults standardUserDefaults] objectForKey:@"nonexistentPreference"] containsObject:@"Another"]);

    [[NSUserDefaults standardUserDefaults] synchronize];
}

CF_EXPORT void CFPreferencesFlushCaches(void);

TEST(NSUserDefaults, Flush) {
    [[NSUserDefaults standardUserDefaults] setObject:@"Cheddar" forKey:@"FavoriteCheese"];
    CFPreferencesFlushCaches();

    NSString* actualCheese = [[NSUserDefaults standardUserDefaults] stringForKey:@"FavoriteCheese"];
    EXPECT_OBJCEQ(@"Cheddar", actualCheese);
    [[NSUserDefaults standardUserDefaults] setObject:@"Swiss" forKey:@"FavoriteCheese"];
    actualCheese = [[NSUserDefaults standardUserDefaults] stringForKey:@"FavoriteCheese"];
    EXPECT_OBJCEQ(@"Swiss", actualCheese);
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FavoriteCheese"];
    actualCheese = [[NSUserDefaults standardUserDefaults] stringForKey:@"FavoriteCheese"];
    EXPECT_OBJCEQ(nil, actualCheese);
    CFPreferencesFlushCaches();
    actualCheese = [[NSUserDefaults standardUserDefaults] stringForKey:@"FavoriteCheese"];
    EXPECT_OBJCEQ(nil, actualCheese);
    [[NSUserDefaults standardUserDefaults] setObject:@"Cheddar" forKey:@"FavoriteCheese"];
    CFPreferencesFlushCaches();
}