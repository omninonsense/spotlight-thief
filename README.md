# Steal the Spotlight

Shitty, half-assed Ruby script that copies all the _local_ Windows Spotlight desktop/mobile wallpapers to a more convenient/accessible location.

Cheesy name too, innit.

## Setup

The only version of Window this was tested with was Widnows 10. No idea if Windows 8 even has this feature.

Download/clone the repo, and then install the dependencies by running something like:

### Additional Linux requirements

The script expects [`udisksctl`](https://www.freedesktop.org/wiki/Software/udisks/) ([`udisks2`](https://www.archlinux.org/packages/?name=udisks2) package for Arch Linux users) to be available for mounting Linux under certain conditions (see Linux usage for more details).

However, if you mounted Windows yourself before running the script, `udisksctl` won't be required.


~~~
 > bundle install --path vendor/bundle
~~~

That should do it for the setup part.

## Usage

The script can read an environment variable called `SPOTLIGHT_DEST`, which determins where the images will be copied.
If the variable is not provided, the platform-specific default destination will be used. See below for detailes about that.

See below for detailed instructions regarding usage in Linux/Windows.

### Linux

The script accepts two positional arguments:

  1. Windows _username_
  2. Windows location

To be more precise, the "username" part is actually the last part of `%HOMEPATH%` (ie `johndoe` in `C:\Users\johndoe`).
Not sure if this is always the username on Windows; I vaguely remember seeing full names in that place.

Windows loacation can be the device (eg `/dev/nvme1n1p4` on my Laptop), *or* the mount-point (eg `/run/media/windows10`).
In case the block device is provided, it will use `udisksctl` to mount the Windows NTFS filsystem in read-only mode and then unmount when done. Mounting is done in read-only mode, so it should be safe to mount even hybernated Windowses (is that even a valid word?).

Example:

~~~
> bundle exec steal.rb ninom /dev/nvme1n1p4
~~~
~~~
Mounted /dev/nvme1n1p4 at /run/media/nino/9A3EB8C43EB89AA9.
SRC: /run/media/nino/9A3EB8C43EB89AA9/Users/ninom/AppData/Local/Packages/Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy/LocalState/Assets
DEST: /home/nino/Pictures/Spotlight
Stealing.........................................................................................................................
Unmounted /dev/nvme1n1p4.
~~~

Default destination is `$HOME/Pictures/Spotlight`

# Windows

Just execute the script (without any arguments). It should work in theory, but it wasn't tested on Windows.

Default destination is `%HOMEPATH%/Pictures/Spotlight`

# License

CC0 or some shit.
