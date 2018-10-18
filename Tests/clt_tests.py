#!/usr/bin/python -u
#
# Tests for platypus command line tool
#

import os
import sys
import re
import subprocess
import plistlib
import shutil

def profile_plist_for_args(args):
    pnargs = ["./platypus"]
    pnargs.extend(args)
    pnargs.extend(['-O', '-'])
    out = subprocess.check_output(pnargs)
    return plistlib.readPlistFromString(out)

def create_app_with_args(args, name='MyApp'):
    open('dummy_script', 'w').close()
    pnargs = ["./platypus"]
    pnargs.extend(args)
    pnargs.extend(['--overwrite', '--name', name, 'dummy_script', name + '.app'])
    with open(os.devnull, 'w') as devnull:
        out = subprocess.check_output(pnargs, stderr=devnull)
    return 'MyApp.app'

os.chdir(os.path.dirname(os.path.realpath(__file__)))

# Dump default profile plist to stdout
plist = profile_plist_for_args([])

print("Checking basic sanity of default profile")
assert(plist['Version'] == '1.0')
assert(plist['InterpreterPath'] == '/bin/sh')
assert(plist['InterfaceType'] == 'Text Window')
assert(len(plist['BundledFiles']) == 0)
assert(plist['Authentication'] == False)
assert(plist['Name'] != '')
assert(re.match('\w+\.\w+\.\w+', plist['Identifier']))


print("Profile generation: Testing boolean switches")

boolean_opts = {
    '-A': 'Authentication',
    '-D': ['Droppable', 'AcceptsFiles'],
    '-F': 'AcceptsText',
    '-N': 'DeclareService',
    '-B': 'RunInBackground',
#-R, --quit-after-execution RemainRunning
    '-Z': 'PromptForFileOnLaunch',
    '-c': 'StatusItemUseSystemFont',
    '-x': 'UseXMLPlistFormat',
    '-d': 'DevelopmentVersion',
    '-l': 'OptimizeApplication',
    '-y': 'Overwrite'
}

for k,v in boolean_opts.iteritems():
    plist = profile_plist_for_args([k])

    l = v
    if isinstance(v, basestring):
        l = [v]
    for m in l:
        assert(plist[m] == True)


print("Profile generation: Testing strings")

string_opts = {
     '-a': ['Name', 'MyAppName'],
     '-o': ['InterfaceType', 'Progress Bar'],
     '-p': ['InterpreterPath', '/usr/bin/perl'],
     '-V': ['Version', '3.2'],
     '-u': ['Author', 'Alan Smithee'],
     '-I': ['Identifier', 'org.something.Blergh'],
     '-b': ['TextBackground', '#000000'],
     '-g': ['TextForeground', '#ffeeee'],
#     '-n': ['TextFont', 'Comic Sans 13'],
     '-K': ['StatusItemDisplayType', 'Icon'],
     '-Y': ['StatusItemTitle', 'MySillyTitle'],
}

for k,v in string_opts.iteritems():
    plist = profile_plist_for_args([k, v[1]])
    assert(plist[v[0]] == v[1])

print("Profile generation: Testing data args")

dummy_icon_path = 'dummy.icns'
data_opts = {
    '-i': ['IconPath', dummy_icon_path],
    '-Q': ['DocIconPath', dummy_icon_path],
    '-L': ['StatusItemIcon', dummy_icon_path]
}
for k,v in data_opts.iteritems():
    plist = profile_plist_for_args([k, v[1]])
#    print plist[v[0]]
    assert(plist[v[0]] != None)


print("Profile generation: Testing flags w. multiple args")

# Create dummy bundled files
open('dummy1', 'w').close()
open('dummy2', 'w').close()

multiple_items_opts = {
    '-G': ['InterpreterArgs', ['-a','-b','-c']],
    '-C': ['ScriptArgs', ['-e','-f','-g']],
    '-f': ['BundledFiles', [os.path.abspath('dummy1'),os.path.abspath('dummy2')]],
    '-X': ['Suffixes', ['txt','png','pdf']],
    '-T': ['UniformTypes', ['public.text', 'public.rtf']],
    '-U': ['URISchemes', ['https', 'ssh']]
}

for k,v in multiple_items_opts.iteritems():
    plist = profile_plist_for_args([k, '|'.join(v[1])])
    items = plist[v[0]]
    
    #print items
    for i in items:
        assert(i in v[1])

os.remove('dummy1')
os.remove('dummy2')


print("Verifying app directory structure")

app_path = create_app_with_args([])

files = [
    app_path + '/',
    app_path + '/Contents',
    app_path + '/Contents/Info.plist',
    app_path + '/Contents/MacOS',
    app_path + '/Contents/MacOS/MyApp',
    app_path + '/Contents/Resources',
    app_path + '/Contents/Resources/AppIcon.icns',
    app_path + '/Contents/Resources/AppSettings.plist',
    app_path + '/Contents/Resources/MainMenu.nib',
    app_path + '/Contents/Resources/script'
]

for p in files:
    assert(os.path.exists(p))

assert(os.access(files[4], os.X_OK)) # app binary
assert(os.access(files[9], os.X_OK)) # script



# Verify keys in AppSettings.plist

# Create new app from python, perl scripts, verify
# that correct interpreter is automatically selected



shutil.rmtree('MyApp.app')
