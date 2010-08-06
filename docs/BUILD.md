Prerequisites
=============

First of all we **highly** recommend to execute the build process by
using a normal user account. Avoid root super powers here, since
permission errors triggered by various PKGBUILDs might exist.

Before proceeding, be sure to have:

- kernel26-pwn installed
- grub installed (preferably grub-gfx)

After that, you have to regen aufs2 from lkm-skel/ and install it before
proceeding with the build of aufs2-util.

At the end you should have these packages installed:

- kernel26-pwn
- aufs2 (-pwn tainted)

You should keep these packages installed until explictly indicated.

Duplicated packages
===================

There are various duplicates packages in lkm-skel/ directory.

- aufs2 and aufs-util:

    Remember that these two packages (aufs2 and aufs2-util) are kept in
    lkm-skel/ due to the absence of KDIR tricks in aufs2-util build
    process. This is the only difference between our version and the ABS
    one.

    If a newer version is present in ABS be sure to sync it before the
    release.

- tiacx

    The only difference is the patch provided by aircrack team. So take
    care to take synced this package too.

- open-vm-tools-modules and virtualbox-ose

    Some customization to make the build process suitable to create
    modules for our tainted kernel.

Local Modules
=============

Before each release be sure to:

- Update the kernel accordingly
- Sync duplicated modules with ABS

After that generate fresh PKGBUILDs from lkm-skel/ by using:

    $ module-rebuild -a repo/lkm-skel repo/regen-modules
    $ pkg-builder -x repo/regen-modules/ pacman/src/ pacman/pkg/

Extra modules
=============

ArchPwn depends on various external modules. This is a brief list
(extracted from the forced list of module-rebuild tool):

- aufs2
- aufs2-util
- vhba-module
- fcpci
- intel-536ep
- intel-537
- martian
- slmodem
- virtualbox-ose

Of course every module is taken from ABS tree, so you need to sync your
ABS tree before proceed:

    $ sudo abs
    $ module-rebuild /var/abs repo/regen-modules/
    modulerebuild - >>> - These are the packages that depends on kernel26
    modulerebuild - >>> -          ndiswrapper => done
    modulerebuild - >>> -                aufs2 => done
    modulerebuild - >>> -            intel-537 => done
    modulerebuild - >>> -              slmodem => done
    modulerebuild - >>> -              martian => done
    modulerebuild - >>> -                fcpci => done
    modulerebuild - >>> -               nvidia => done
    modulerebuild - >>> -          intel-536ep => done
    modulerebuild - >>> -            compcache => done
    modulerebuild - >>> -          vhba-module => done
    ...

    $ pkg-builder -x repo/regen-modules/ pacman/src/ pacman/pkg/

After that you should be ready for the next phase.

Create your ISO
===============

At this point everything is done trough a script called mkarchiso. This
requires to have a kernel with aufs2 module installed. So the possible
solutions are:

- proceed with your -ARCH kernel
- use your shiny -PWN kernel

The first options is the best since it doesn't require any module
rebuild and doesn't impact your system in any way. By the way, it's not
all gold. You have to remove aufs2-\* packages (-pwn tainted) that you
have installed in the earlier phases:

    # pacman -Rd aufs2 aufs2-utils
    # rm /var/cache/pacman/aufs2*
    # pacman -S extra/aufs2 extra/aufs2-util
    # rm /var/cache/pacman/aufs2*

Did you see any duplicated lines? Well they are not duplicated. Since
the package names of the -pwn version and the -ARCH version are the same
you have to be sure to clean up the pacman cache to avoid package
corruption in the install phase.

Another requirement for mkarchiso script is mksquashfs binary provided
by squashfs-tools PKGBUILD (it's located in repo/base).

    # pacman -U pacman/pkg/squashfs-tools-*

Build your profile
------------------

mkarchiso script provide a flexible way to customize your iso. You could
easilly define a profile and build it without touching or polluting
anything. ArchPwn is organized in two profiles:

- archpwn-mini

    That contains the only strict requirements for pentesters that fits
    in standard CD.

- archpwn-full

    Contains everything you need for a complete penetration testing. You
    could burn the image onto a DVD or use with your favourite USB
    stick.

