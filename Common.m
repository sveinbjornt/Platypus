/*
 Copyright (c) 2003-2017, Sveinbjorn Thordarson <sveinbjornt@gmail.com>
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice, this
 list of conditions and the following disclaimer in the documentation and/or other
 materials provided with the distribution.
 
 3. Neither the name of the copyright holder nor the names of its contributors may
 be used to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */

// App Spec keys
NSString * const AppSpecKey_Creator = @"Creator";
NSString * const AppSpecKey_ExecutablePath = @"ExecutablePath";
NSString * const AppSpecKey_NibPath = @"NibPath";
NSString * const AppSpecKey_DestinationPath = @"Destination";
NSString * const AppSpecKey_Overwrite = @"DestinationOverride";
NSString * const AppSpecKey_SymlinkFiles = @"DevelopmentVersion";
NSString * const AppSpecKey_StripNib = @"OptimizeApplication";
NSString * const AppSpecKey_XMLPlistFormat = @"UseXMLPlistFormat";
NSString * const AppSpecKey_Name = @"Name";
NSString * const AppSpecKey_ScriptPath = @"ScriptPath";
NSString * const AppSpecKey_InterfaceType = @"InterfaceType";
NSString * const AppSpecKey_IconPath = @"IconPath";
NSString * const AppSpecKey_InterpreterPath = @"InterpreterPath";
NSString * const AppSpecKey_InterpreterArgs = @"InterpreterArgs";
NSString * const AppSpecKey_ScriptArgs = @"ScriptArgs";
NSString * const AppSpecKey_Version = @"Version";
NSString * const AppSpecKey_Identifier = @"Identifier";
NSString * const AppSpecKey_Author = @"Author";

NSString * const AppSpecKey_Droppable = @"Droppable";
NSString * const AppSpecKey_Authenticate = @"Authentication";
NSString * const AppSpecKey_RemainRunning = @"RemainRunning";
NSString * const AppSpecKey_RunInBackground = @"ShowInDock";

NSString * const AppSpecKey_BundledFiles = @"BundledFiles";

NSString * const AppSpecKey_Suffixes = @"Suffixes";
NSString * const AppSpecKey_Utis = @"UniformTypes";
NSString * const AppSpecKey_AcceptText = @"AcceptsText";
NSString * const AppSpecKey_AcceptFiles = @"AcceptsFiles";
NSString * const AppSpecKey_Service = @"DeclareService";
NSString * const AppSpecKey_PromptForFile = @"PromptForFileOnLaunch";
NSString * const AppSpecKey_DocIconPath = @"DocIcon";

NSString * const AppSpecKey_TextFont = @"TextFont";
NSString * const AppSpecKey_TextSize = @"TextSize";
NSString * const AppSpecKey_TextColor = @"TextForeground";
NSString * const AppSpecKey_TextBackgroundColor = @"TextBackground";

NSString * const AppSpecKey_StatusItemDisplayType = @"StatusItemDisplayType";
NSString * const AppSpecKey_StatusItemTitle = @"StatusItemTitle";
NSString * const AppSpecKey_StatusItemIcon = @"StatusItemIcon";
NSString * const AppSpecKey_StatusItemUseSysfont = @"StatusItemUseSystemFont";
NSString * const AppSpecKey_StatusItemIconIsTemplate = @"StatusItemIconIsTemplate";

NSString * const AppSpecKey_IsExample = @"Example"; // examples only
NSString * const AppSpecKey_ScriptText = @"Script"; // examples only
NSString * const AppSpecKey_ScriptName = @"ScriptName"; // examples only

NSString * const AppSpecKey_InterpreterPath_Legacy = @"Interpreter";
NSString * const AppSpecKey_InterfaceType_Legacy = @"Output";

// NSUserDefaults keys for Platypus app
NSString * const DefaultsKey_BundleIdentifierPrefix = @"DefaultBundleIdentifierPrefix";
NSString * const DefaultsKey_DefaultEditor = @"DefaultEditor";
NSString * const DefaultsKey_RevealApplicationWhenCreated = @"RevealApplicationWhenCreated";
NSString * const DefaultsKey_OpenApplicationWhenCreated = @"OpenApplicationWhenCreated";
NSString * const DefaultsKey_DefaultAuthor = @"DefaultAuthor";
NSString * const DefaultsKey_SymlinkFiles = @"OnCreateDevVersion";
NSString * const DefaultsKey_StripNib = @"OnCreateOptimizeNib";
NSString * const DefaultsKey_UseXMLPlistFormat = @"OnCreateUseXMLPlist";

// NSUserDefaults keys for ScriptExec app
NSString * const ScriptExecDefaultsKey_UserFontSize = @"UserFontSize";
NSString * const ScriptExecDefaultsKey_ShowDetails = @"UserShowDetails";

// functions

BOOL UTTypeIsValid(NSString *inUTI) {
    NSString *reverseDNSRegEx = @"^[A-Za-z]{2,6}((?!-)\\.[A-Za-z0-9-]{1,63}(?<!-))+$";
    NSPredicate *test = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", reverseDNSRegEx];
    return [test evaluateWithObject:inUTI];
}

BOOL BundleIdentifierIsValid(NSString *bundleIdentifier) {
    BOOL validUTI = UTTypeIsValid(bundleIdentifier);
    BOOL hasThreeComponents = ([[bundleIdentifier componentsSeparatedByString:@"."] count] >= 3);
    return (validUTI && hasThreeComponents);
}
