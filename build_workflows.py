#!/usr/bin/env python3
from __future__ import annotations

import plistlib
import shutil
import uuid
from pathlib import Path


ROOT = Path(__file__).resolve().parent
OUTPUTS = ROOT / "Workflows"


def run_shell_action(command: str) -> dict:
    return {
        "actions": [
            {
                "action": {
                    "ActionBundlePath": "/System/Library/Automator/Run Shell Script.action",
                    "ActionName": "Run Shell Script",
                    "ActionParameters": {
                        "CheckedForUserDefaultShell": True,
                        "COMMAND_STRING": command,
                        "inputMethod": 1,
                        "shell": "/bin/zsh",
                        "source": "",
                    },
                    "AMAccepts": {
                        "Container": "List",
                        "Optional": True,
                        "Types": ["com.apple.cocoa.string"],
                    },
                    "AMActionVersion": "2.0.3",
                    "AMApplication": ["Automator"],
                    "AMParameterProperties": {
                        "CheckedForUserDefaultShell": {},
                        "COMMAND_STRING": {},
                        "inputMethod": {},
                        "shell": {},
                        "source": {},
                    },
                    "AMProvides": {
                        "Container": "List",
                        "Types": ["com.apple.cocoa.string"],
                    },
                    "arguments": {
                        "0": {
                            "default value": 0,
                            "name": "inputMethod",
                            "required": "0",
                            "type": "0",
                            "uuid": "0",
                        },
                        "1": {
                            "default value": False,
                            "name": "CheckedForUserDefaultShell",
                            "required": "0",
                            "type": "0",
                            "uuid": "1",
                        },
                        "2": {
                            "default value": "",
                            "name": "source",
                            "required": "0",
                            "type": "0",
                            "uuid": "2",
                        },
                        "3": {
                            "default value": "",
                            "name": "COMMAND_STRING",
                            "required": "0",
                            "type": "0",
                            "uuid": "3",
                        },
                        "4": {
                            "default value": "/bin/sh",
                            "name": "shell",
                            "required": "0",
                            "type": "0",
                            "uuid": "4",
                        },
                    },
                    "BundleIdentifier": "com.apple.RunShellScript",
                    "CanShowSelectedItemsWhenRun": False,
                    "CanShowWhenRun": True,
                    "Category": ["AMCategoryUtilities"],
                    "CFBundleVersion": "2.0.3",
                    "Class Name": "RunShellScriptAction",
                    "InputUUID": str(uuid.uuid4()).upper(),
                    "isViewVisible": 1,
                    "Keywords": ["Shell", "Script", "Command", "Run", "Unix"],
                    "location": "720.000000:305.000000",
                    "nibPath": "/System/Library/Automator/Run Shell Script.action/Contents/Resources/Base.lproj/main.nib",
                    "OutputUUID": str(uuid.uuid4()).upper(),
                    "UnlocalizedApplications": ["Automator"],
                    "UUID": str(uuid.uuid4()).upper(),
                },
                "isViewVisible": 1,
            }
        ],
        "AMApplicationBuild": "528",
        "AMApplicationVersion": "2.10",
        "AMDocumentVersion": "2",
        "connectors": {},
        "workflowMetaData": {
            "applicationBundleID": "com.apple.finder",
            "applicationBundleIDsByPath": {
                "/System/Library/CoreServices/Finder.app": "com.apple.finder"
            },
            "applicationPath": "/System/Library/CoreServices/Finder.app",
            "applicationPaths": ["/System/Library/CoreServices/Finder.app"],
            "customImageFileExtension": "png",
            "inputTypeIdentifier": "com.apple.Automator.fileSystemObject.PDF",
            "outputTypeIdentifier": "com.apple.Automator.nothing",
            "presentationMode": 15,
            "processesInput": False,
            "serviceApplicationBundleID": "com.apple.finder",
            "serviceApplicationPath": "/System/Library/CoreServices/Finder.app",
            "serviceInputTypeIdentifier": "com.apple.Automator.fileSystemObject.PDF",
            "serviceOutputTypeIdentifier": "com.apple.Automator.nothing",
            "serviceProcessesInput": False,
            "systemImageName": "NSTouchBarDocuments",
            "useAutomaticInputType": False,
            "workflowTypeIdentifier": "com.apple.Automator.servicesMenu",
        },
    }


def info_plist(menu_name: str) -> dict:
    return {
        "NSServices": [
            {
                "NSBackgroundColorName": "background",
                "NSIconName": "NSTouchBarDocuments",
                "NSMenuItem": {"default": menu_name},
                "NSMessage": "runWorkflowAsService",
                "NSRequiredContext": {"NSApplicationIdentifier": "com.apple.finder"},
                "NSSendFileTypes": ["com.adobe.pdf"],
            }
        ]
    }


def write_workflow(bundle_name: str, menu_name: str, command: str) -> None:
    bundle = OUTPUTS / f"{bundle_name}.workflow"
    contents = bundle / "Contents"

    if bundle.exists():
        shutil.rmtree(bundle)
    contents.mkdir(parents=True)

    with (contents / "Info.plist").open("wb") as file:
        plistlib.dump(info_plist(menu_name), file, sort_keys=False)

    with (contents / "document.wflow").open("wb") as file:
        plistlib.dump(run_shell_action(command), file, sort_keys=False)


def main() -> None:
    OUTPUTS.mkdir(parents=True, exist_ok=True)
    write_workflow(
        "Extract PDF as Images",
        "Extract PDF as Images",
        (ROOT / "scripts/pdf_extract_all_pages.sh").read_text(),
    )
    write_workflow(
        "Extract Page to Image...",
        "Extract Page to Image...",
        '\n'.join([
            'app="/Applications/PDF Page Extractor.app"',
            'if [[ ! -d "$app" ]]; then app="$HOME/Applications/PDF Page Extractor.app"; fi',
            '/usr/bin/open -n "$app" --args "$@"',
        ]),
    )


if __name__ == "__main__":
    main()
