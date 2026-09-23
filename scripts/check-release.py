"""Inspect an archived native app. Signing is mandatory unless explicitly skipped."""
import argparse, hashlib, json, pathlib, plistlib, subprocess, sys
parser = argparse.ArgumentParser()
parser.add_argument('archive', type=pathlib.Path)
parser.add_argument('--allow-unsigned', action='store_true', help='Inspect packaging only; does not establish upload readiness.')
args = parser.parse_args()
root = pathlib.Path(__file__).resolve().parents[1]
app = args.archive / 'Products/Applications/TennisIQ.app'
errors = []
def check(condition, message):
    print(('PASS ' if condition else 'FAIL ') + message)
    if not condition: errors.append(message)
check(app.exists(), 'archive contains TennisIQ.app')
if not app.exists(): sys.exit(1)
info = plistlib.loads((app / 'Info.plist').read_bytes())
check(info.get('CFBundleIdentifier') == 'com.srqtennis.TennisIQ', 'bundle ID')
check(info.get('CFBundleShortVersionString') == '1.0', 'release version 1.0')
check(info.get('CFBundleIcons', {}).get('CFBundlePrimaryIcon', {}).get('CFBundleIconName') == 'AppIcon', 'primary app icon')
check(info.get('ITSAppUsesNonExemptEncryption') is False, 'encryption declaration')
check(any('tennisiq' in item.get('CFBundleURLSchemes', []) for item in info.get('CFBundleURLTypes', [])), 'friendly challenge URL scheme')
manifest = plistlib.loads((app / 'PrivacyInfo.xcprivacy').read_bytes())
check(manifest.get('NSPrivacyTracking') is False and manifest.get('NSPrivacyCollectedDataTypes') == [], 'no tracking or developer collection declared')
check({'NSPrivacyAccessedAPIType':'NSPrivacyAccessedAPICategoryUserDefaults', 'NSPrivacyAccessedAPITypeReasons':['CA92.1']} in manifest.get('NSPrivacyAccessedAPITypes', []), 'local preferences required-reason declaration')
check((app / 'questions.json').read_bytes() == (root / 'web/questions.json').read_bytes(), 'audited bank bundled unchanged')
check(not list(app.rglob('*.storekit')), 'no local StoreKit test catalog shipped')
check(not list(app.rglob('*.xctest')), 'no test bundle shipped')
check((app / 'Assets.car').exists(), 'compiled assets present')
if args.allow_unsigned:
    print('NOT UPLOAD READY: signing deliberately skipped; local packaging evidence only.')
else:
    signature = subprocess.run(['codesign','--verify','--deep','--strict',str(app)], capture_output=True)
    check(signature.returncode == 0, 'valid code signature')
    check((app / 'embedded.mobileprovision').exists(), 'embedded provisioning profile')
print(f'{len(errors)} failed checks')
sys.exit(bool(errors))
