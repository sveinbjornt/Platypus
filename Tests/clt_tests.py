#!/usr/bin/python3 -u
#
# Tests for platypus command line tool
#

import os
import re
import subprocess
import plistlib


CLT_BINARY = os.path.dirname(os.path.realpath(__file__)) + "/platypus"


def profile_plist_for_args(args):
    pnargs = [CLT_BINARY]
    pnargs.extend(args)
    pnargs.extend(["-O", "-"])
    out = subprocess.check_output(pnargs)
    return plistlib.loads(out)


def create_app_with_args(args, name="MyApp"):
    pnargs = [CLT_BINARY]
    pnargs.extend(args)
    pnargs.extend(["--overwrite", "--name", name, "args.py", name + ".app"])
    with open(os.devnull, "w") as devnull:
        out = subprocess.check_output(pnargs, stderr=devnull)
    return "MyApp.app"


def create_profile_with_args(args, name="dummy.profile"):
    pass


def run_app(name="MyApp", args=[]):
    with open(os.devnull, "w") as devnull:
        cmd = ["./" + name + ".app/Contents/MacOS/" + name]
        cmd.extend(args)
        out = subprocess.check_output(cmd, stderr=devnull)
    with open("args.txt", "r") as f:
        arglist = [l.rstrip("\n") for l in f.readlines()]

    return arglist


os.chdir(os.path.dirname(os.path.realpath(__file__)))


print("Checking basic sanity of default profile")

plist = profile_plist_for_args([])

assert plist["Version"] == "1.0"
assert plist["InterpreterPath"] == "/bin/sh"
assert plist["InterfaceType"] == "Text Window"
assert len(plist["BundledFiles"]) == 0
assert plist["Authentication"] == False
assert plist["Name"] != ""
assert re.match(r"\w+\.\w+\.\w+", plist["Identifier"])


print("Profile generation: Testing boolean switches")

boolean_opts = {
    "-A": "Authentication",
    "-D": ["Droppable", "AcceptsFiles"],
    "-F": "AcceptsText",
    "-N": "DeclareService",
    "-B": "RunInBackground",
    "-Z": "PromptForFileOnLaunch",
    "-c": "StatusItemUseSystemFont",
    "-d": "DevelopmentVersion",
    "-l": "OptimizeApplication",
    "-y": "Overwrite",
}

for k, v in boolean_opts.items():
    plist = profile_plist_for_args([k])

    lst = v
    if isinstance(v, str):
        lst = [v]
    for m in lst:
        assert plist[m] == True

inv_boolean_opts = {"-R": "RemainRunning"}
for k, v in inv_boolean_opts.items():
    plist = profile_plist_for_args([k])
    assert plist[v] == False


print("Profile generation: Testing strings")

string_opts = {
    "-a": ["Name", "MyAppName"],
    "-o": ["InterfaceType", "Progress Bar"],
    "-p": ["InterpreterPath", "/usr/bin/perl"],
    "-V": ["Version", "3.2"],
    "-u": ["Author", "Alan Smithee"],
    "-I": ["Identifier", "org.something.Blergh"],
    "-b": ["TextBackground", "#000000"],
    "-g": ["TextForeground", "#ffeeee"],
    #     '-n': ['TextFont', 'Comic Sans 13'],
    "-K": ["StatusItemDisplayType", "Icon"],
    "-Y": ["StatusItemTitle", "MySillyTitle"],
}

for k, v in string_opts.items():
    plist = profile_plist_for_args([k, v[1]])
    assert plist[v[0]] == v[1]

print("Profile generation: Testing data args")

dummy_icon_path = os.path.abspath("dummy.icns")
data_opts = {
    "-i": ["IconPath", dummy_icon_path],
    "-Q": ["DocIconPath", dummy_icon_path],
    "-L": ["StatusItemIcon", dummy_icon_path],
}
for k, v in data_opts.items():
    plist = profile_plist_for_args([k, v[1]])
    #    print plist[v[0]]
    assert plist[v[0]] != None


print("Profile generation: Testing flags w. multiple args")

# Create dummy bundled files
open("dummy1", "w").close()
open("dummy2", "w").close()

multiple_items_opts = {
    "-G": ["InterpreterArgs", ["-a", "-b", "-c"]],
    "-C": ["ScriptArgs", ["-e", "-f", "-g"]],
    "-f": ["BundledFiles", [os.path.abspath("dummy1"), os.path.abspath("dummy2")]],
    "-X": ["Suffixes", ["txt", "png", "pdf"]],
    "-T": ["UniformTypes", ["public.text", "public.rtf"]],
    "-U": ["URISchemes", ["https", "ssh"]],
}

for k, v in multiple_items_opts.items():
    plist = profile_plist_for_args([k, "|".join(v[1])])
    items = plist[v[0]]

    for i in items:
        assert i in v[1]

# Remove dummy files
os.remove("dummy1")
os.remove("dummy2")


print("Verifying app directory structure and permissions")

app_path = create_app_with_args(["-R"])

files = [
    app_path + "/",
    app_path + "/Contents",
    app_path + "/Contents/Info.plist",
    app_path + "/Contents/MacOS",
    app_path + "/Contents/MacOS/MyApp",
    app_path + "/Contents/Resources",
    app_path + "/Contents/Resources/AppSettings.plist",
    app_path + "/Contents/Resources/MainMenu.nib",
    app_path + "/Contents/Resources/script",
]

for p in files:
    print("Verifying existence of " + p)
    assert os.path.exists(p)

assert os.access(files[4], os.X_OK)  # app binary
assert os.access(files[8], os.X_OK)  # script


# Verify keys in AppSettings.plist

# Create new app from python, perl scripts, verify
# that correct interpreter is automatically selected


# Run app
print("Verifying app argument handling")
assert run_app(args=["a", "b", "c"]) == ["a", "b", "c"]


# Create app with droppable settings, test opening file


# shutil.rmtree('MyApp.app')
