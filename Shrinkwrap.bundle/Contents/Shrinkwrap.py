"""Shrinkwrap -> Petrify migration stub.

In v2.0.0 the Shrinkwrap add-in was renamed Petrify (Petrify.bundle). Installs
from before that auto-update with an updater that only installs
Shrinkwrap.bundle and checks its SHRINKWRAP_VERSION against the release tag.
So the repo keeps this stub under the old name. Old installs update into it,
and on the next Fusion start it:

1. installs Petrify.bundle from the latest GitHub release (unless present),
2. removes itself (Shrinkwrap.bundle) from ApplicationPlugins,
3. asks the user to restart Fusion.

It adds no buttons. Keep it in the repo while pre-2.0 installs may exist, and
keep SHRINKWRAP_VERSION equal to every release tag (bump_version.ps1 does it).
"""

import adsk.core
import importlib.util
import json
import os
import shutil
import threading
import time
import traceback

MIGRATION_STUB = True   # Petrify recognises (and cleans up) the stub by this line.

# Must equal the release tag, or pre-rename updaters refuse to install this.
SHRINKWRAP_VERSION = '2.0.0'

EVENT_ID = 'DaneccaShrinkwrapMigration'
START_DELAY = 5         # seconds, so Fusion has finished starting
TITLE = 'Shrinkwrap is now Petrify'

_HERE = os.path.dirname(os.path.abspath(__file__))
handlers = []


def _log(msg):
    try:
        adsk.core.Application.get().log(f'[Shrinkwrap migration] {msg}')
    except Exception:
        pass


def _load_updater():
    """Petrify's updater, shipped next to this file under its own module name."""
    spec = importlib.util.spec_from_file_location(
        'shrinkwrap_migration_updater', os.path.join(_HERE, 'shrinkwrap_migration_updater.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _migrate():
    """Install Petrify if needed, then remove this stub. No Fusion API: runs off the main thread.

    Returns 'installed' if Petrify was installed now, 'present' if it already
    was. Raises on failure.
    """
    u = _load_updater()
    addins = u.addins_install_path()
    petrify = os.path.join(addins, u.BUNDLE_NAME)
    if os.path.isfile(os.path.join(petrify, 'PackageContents.xml')):
        outcome = 'present'
    else:
        token = u.cached_github_token()
        _latest, tag = u.latest_release(token)
        u.download_and_install(tag, token, log=_log)
        outcome = 'installed'

    # Remove this stub, but only from ApplicationPlugins: never a repo checkout.
    bundle = os.path.dirname(_HERE)
    if os.path.normcase(os.path.dirname(bundle)) == os.path.normcase(addins) and \
            os.path.isdir(bundle):
        retired = bundle + '.retired'
        shutil.rmtree(retired, ignore_errors=True)
        os.replace(bundle, retired)
        shutil.rmtree(retired, ignore_errors=True)
        _log('Removed Shrinkwrap.bundle')
    return outcome


class _MigrationDoneHandler(adsk.core.CustomEventHandler):
    """Main-thread end: tell the user what happened."""

    def __init__(self):
        super().__init__()

    def notify(self, args):
        try:
            info = json.loads(args.additionalInfo)
            ui = adsk.core.Application.get().userInterface
            if info.get('outcome') == 'installed':
                ui.messageBox(
                    'The Shrinkwrap add-in has been renamed Petrify, and Petrify has just '
                    'been installed in its place.\n\n'
                    'Please restart Fusion to start using it. In Solid > Modify you will find:\n'
                    '  - Petrify (was Shrinkwrap)\n'
                    '  - Ordain Mass (was Set Mass)\n'
                    '  - Petrify Updates', TITLE)
            elif info.get('error'):
                ui.messageBox(
                    'The Shrinkwrap add-in has been renamed Petrify, but installing Petrify '
                    f'failed:\n\n{info["error"]}\n\n'
                    'It will be tried again the next time Fusion starts. You can also '
                    'install it by hand from https://github.com/Danecca-Ltd/Petrify '
                    '(Deploy.bat).', TITLE)
        except Exception:
            _log(traceback.format_exc())


def run(context):
    try:
        app = adsk.core.Application.get()
        try:
            app.unregisterCustomEvent(EVENT_ID)
        except Exception:
            pass
        event = app.registerCustomEvent(EVENT_ID)
        handler = _MigrationDoneHandler()
        event.add(handler)
        handlers.append(handler)

        def worker():
            time.sleep(START_DELAY)
            try:
                result = {'outcome': _migrate()}
            except Exception as e:
                _log('Migration failed:\n' + traceback.format_exc())
                result = {'error': str(e) or e.__class__.__name__}
            app.fireCustomEvent(EVENT_ID, json.dumps(result))

        threading.Thread(target=worker, name='ShrinkwrapMigration', daemon=True).start()
    except Exception:
        _log('Migration not started:\n' + traceback.format_exc())


def stop(context):
    try:
        adsk.core.Application.get().unregisterCustomEvent(EVENT_ID)
    except Exception:
        pass
    handlers.clear()
