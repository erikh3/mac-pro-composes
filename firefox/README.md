# stepca certificates

~~Replace certificates from `service-certs` to `firefox/config/ssl`.~~

```shell
cd stepca && ./distribute-certs.zsh
```

# Tips

When you cannot connect to KASM VNC, nuke currently open tabs.

>[!note]
> Edit the file path.

```shell
# exec into firefox container
rm /config/.mozilla/firefox/qoz63v3q.default-release/sessionstore-backups/*.jsonlz4
```

## Dwhelper companion app

<details>
  <summary><h2>Manual installation of dwhelper companion app</h2></summary>


**⚠️ Manual installation is no longer needed! ⚠️**

[install_dwhelper_coapp.sh](firefox/scripts/install_dwhelper_coapp.sh) script runs on [reboot](firefox/crontabs/root).

---

Install dwhelper companion app (this needs to be done only once!).

1. `apt-get update && apt-get install bzip2 -y`
2. `curl -sSLf https://github.com/aclap-dev/vdhcoapp/releases/latest/download/install.sh | bash`

```
Downloading: https://github.com/aclap-dev/vdhcoapp/releases/latest/download/vdhcoapp-linux-aarch64.tar.bz2
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
100 52.9M  100 52.9M    0     0  4771k      0  0:00:11  0:00:11 --:--:-- 7660k
Extracting tarball…
/tmp/vdhcoapp-SWUDDa: bzip2 compressed data, block size = 900k
Registering CoApp
Installing…
VdhCoApp : VdhCoApp is ready to be used
CoApp successfuly installed under '~/.local/share/vdhcoapp'.
To uninstall, run '~/.local/share/vdhcoapp/vdhcoapp uninstall' and remove '~/.local/share/vdhcoapp'.
Re-run that script to update the coapp.
```

3. Install Firefox specific [native manifests](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Native_manifests) to correct location

https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Native_manifests#manifest_location

## Install for user

Install the coapp to volume (which persists across container restarts).

```shell
~/.local/share/vdhcoapp/vdhcoapp install --user
```

```
Installing…
Flatpak is installed. Making the coapp available from browser sandboxes:
Linked coapp within org.mozilla.firefox.
Linked coapp within com.brave.Browser.
Linked coapp within com.google.Chrome.
Linked coapp within com.google.ChromeDev.
Linked coapp within org.chromium.Chromium.
Linked coapp within com.github.Eloston.UngoogledChromium.
Linked coapp within com.microsoft.Edge.
Linked coapp within com.microsoft.EdgeDev.
Writing /config/.mozilla/native-messaging-hosts/net.downloadhelper.coapp.json
Writing /config/.var/app/org.mozilla.firefox/.mozilla/native-messaging-hosts/net.downloadhelper.coapp.json
VdhCoApp : VdhCoApp is ready to be used
```

After installation check Firefox extention:

Settings -> More settings...

```
version: 9.3.7.2
target: mozilla
channel: stable
lang: en-US
coapp: {"found":true,"path":"/config/.local/share/vdhcoapp/vdhcoapp","version":"2.0.19","new_version":false}
license: {"unneeded":true}
platform: aarch64 linux
UA: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:136.0) Gecko/20100101 Firefox/136.0
{
    "privacy_accept": true,
    "used_history_button": true,
    "view_options": {
        "all_tabs": false,
        "low_quality": false,
        "sort_by_status": true,
        "sort_reverse": false,
        "show_button_clean": true,
        "show_button_clean_all": false,
        "show_button_convert_local": false,
        "hide_downloaded": false
    },
    "open_count_store": 7,
    "successfull_dl": 1
}
```
</details>
