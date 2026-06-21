# List Posit Package Manager platforms

Queries the Posit Package Manager `/__api__/status` endpoint and returns
a data frame of supported distributions.

## Usage

``` r
ppm_platforms(base_url = ppm_default_base_url())
```

## Arguments

- base_url:

  Posit Package Manager base URL.

## Value

A data frame of platform records reported by Package Manager.

## See also

Other ppm:
[`check_ppm()`](https://choxos.github.io/sysreqR/reference/check_ppm.md),
[`ppm_repo()`](https://choxos.github.io/sysreqR/reference/ppm_repo.md),
[`ppm_sysreqs()`](https://choxos.github.io/sysreqR/reference/ppm_sysreqs.md),
[`use_ppm()`](https://choxos.github.io/sysreqR/reference/use_ppm.md)

## Examples

``` r
# \donttest{
ppm_platforms()
#>                     name      os                   binaryDisplay      binaryURL
#> 1                centos7   linux                   CentOS/RHEL 7        centos7
#> 2                centos8   linux                   CentOS/RHEL 8        centos8
#> 3                  rhel9   linux                   Rocky Linux 9          rhel9
#> 4                 rhel10   linux                  Rocky Linux 10         rhel10
#> 5             opensuse15   linux      OpenSUSE 15.1, SLES 15 SP1     opensuse15
#> 6            opensuse152   linux      OpenSUSE 15.2, SLES 15 SP2    opensuse152
#> 7            opensuse153   linux      OpenSUSE 15.3, SLES 15 SP3    opensuse153
#> 8            opensuse154   linux      OpenSUSE 15.4, SLES 15 SP4    opensuse154
#> 9            opensuse155   linux      OpenSUSE 15.5, SLES 15 SP5    opensuse155
#> 10           opensuse156   linux  OpenSUSE 15.6, SLES 15 SP6/SP7    opensuse156
#> 11            opensuse42   linux      OpenSUSE 42.3, SLES 12 SP5     opensuse42
#> 12                 rhel7   linux                   CentOS/RHEL 7        centos7
#> 13                 rhel8   linux                          RHEL 8        centos8
#> 14  rhel9 (unused alias)   linux                          RHEL 9          rhel9
#> 15 rhel10 (unused alias)   linux                         RHEL 10         rhel10
#> 16                sles12   linux      OpenSUSE 42.3, SLES 12 SP5     opensuse42
#> 17                sles15   linux      OpenSUSE 15.1, SLES 15 SP1     opensuse15
#> 18               sles152   linux      OpenSUSE 15.2, SLES 15 SP2    opensuse152
#> 19               sles153   linux      OpenSUSE 15.3, SLES 15 SP3    opensuse153
#> 20               sles154   linux      OpenSUSE 15.4, SLES 15 SP4    opensuse154
#> 21               sles155   linux      OpenSUSE 15.5, SLES 15 SP5    opensuse155
#> 22               sles156   linux  OpenSUSE 15.6, SLES 15 SP6/SP7    opensuse156
#> 23                xenial   linux           Ubuntu 16.04 (Xenial)         xenial
#> 24                bionic   linux           Ubuntu 18.04 (Bionic)         bionic
#> 25                 focal   linux            Ubuntu 20.04 (Focal)          focal
#> 26                 jammy   linux            Ubuntu 22.04 (Jammy)          jammy
#> 27                 noble   linux            Ubuntu 24.04 (Noble)          noble
#> 28              resolute   linux         Ubuntu 26.04 (Resolute)       resolute
#> 29                buster   linux              Debian 10 (Buster)         buster
#> 30              bullseye   linux            Debian 11 (Bullseye)       bullseye
#> 31              bookworm   linux            Debian 12 (Bookworm)       bookworm
#> 32                trixie   linux              Debian 13 (Trixie)         trixie
#> 33               windows windows                                               
#> 34                 macos   macos                                               
#> 35        manylinux_2_28   linux manylinux glibc 2.28+ (preview) manylinux_2_28
#> 36              internal   linux                        internal       internal
#>                            display distribution release build_distribution
#> 1                         CentOS 7       centos       7                   
#> 2                         CentOS 8       centos       8                   
#> 3                    Rocky Linux 9   rockylinux       9                   
#> 4                   Rocky Linux 10   rockylinux      10                   
#> 5                    OpenSUSE 15.1     opensuse      15                   
#> 6                    OpenSUSE 15.2     opensuse    15.2                   
#> 7                    OpenSUSE 15.3     opensuse    15.3                   
#> 8                    OpenSUSE 15.4     opensuse    15.4                   
#> 9                    OpenSUSE 15.5     opensuse    15.5                   
#> 10                   OpenSUSE 15.6     opensuse    15.6                   
#> 11                   OpenSUSE 42.3     opensuse    42.3                   
#> 12      Red Hat Enterprise Linux 7       redhat       7                   
#> 13      Red Hat Enterprise Linux 8       redhat       8                   
#> 14      Red Hat Enterprise Linux 9       redhat       9                   
#> 15     Red Hat Enterprise Linux 10       redhat      10                   
#> 16                     SLES 12 SP5          sle    12.3                   
#> 17                     SLES 15 SP1          sle      15                   
#> 18                     SLES 15 SP2          sle    15.2                   
#> 19                     SLES 15 SP3          sle    15.3                   
#> 20                     SLES 15 SP4          sle    15.4                   
#> 21                     SLES 15 SP5          sle    15.5                   
#> 22                 SLES 15 SP6/SP7          sle    15.6                   
#> 23           Ubuntu 16.04 (Xenial)       ubuntu   16.04                   
#> 24           Ubuntu 18.04 (Bionic)       ubuntu   18.04                   
#> 25            Ubuntu 20.04 (Focal)       ubuntu   20.04                   
#> 26            Ubuntu 22.04 (Jammy)       ubuntu   22.04                   
#> 27            Ubuntu 24.04 (Noble)       ubuntu   24.04                   
#> 28         Ubuntu 26.04 (Resolute)       ubuntu   26.04                   
#> 29              Debian 10 (Buster)       debian      10                   
#> 30            Debian 11 (Bullseye)       debian      11                   
#> 31            Debian 12 (Bookworm)       debian      12                   
#> 32              Debian 13 (Trixie)       debian      13                   
#> 33                         Windows      windows     all                   
#> 34                           macOS        macos     all              jammy
#> 35 manylinux glibc 2.28+ (preview)       centos       8                   
#> 36                        internal     internal     all                   
#>    sysReqs binaries hidden official_rspm         arch
#> 1     TRUE     TRUE  FALSE          TRUE       x86_64
#> 2     TRUE     TRUE   TRUE          TRUE       x86_64
#> 3     TRUE     TRUE  FALSE          TRUE x86_64, ....
#> 4     TRUE     TRUE  FALSE          TRUE x86_64, ....
#> 5     TRUE     TRUE   TRUE          TRUE       x86_64
#> 6     TRUE     TRUE   TRUE          TRUE       x86_64
#> 7     TRUE     TRUE   TRUE          TRUE       x86_64
#> 8     TRUE     TRUE   TRUE          TRUE       x86_64
#> 9     TRUE     TRUE   TRUE          TRUE       x86_64
#> 10    TRUE     TRUE  FALSE          TRUE       x86_64
#> 11    TRUE     TRUE   TRUE          TRUE       x86_64
#> 12    TRUE     TRUE  FALSE          TRUE       x86_64
#> 13    TRUE     TRUE  FALSE          TRUE       x86_64
#> 14    TRUE     TRUE  FALSE          TRUE x86_64, ....
#> 15    TRUE     TRUE  FALSE          TRUE x86_64, ....
#> 16    TRUE     TRUE   TRUE          TRUE       x86_64
#> 17    TRUE     TRUE   TRUE          TRUE       x86_64
#> 18    TRUE     TRUE   TRUE          TRUE       x86_64
#> 19    TRUE     TRUE   TRUE          TRUE       x86_64
#> 20    TRUE     TRUE   TRUE          TRUE       x86_64
#> 21    TRUE     TRUE   TRUE          TRUE       x86_64
#> 22    TRUE     TRUE  FALSE          TRUE       x86_64
#> 23    TRUE     TRUE   TRUE          TRUE       x86_64
#> 24    TRUE     TRUE   TRUE          TRUE       x86_64
#> 25    TRUE     TRUE   TRUE          TRUE       x86_64
#> 26    TRUE     TRUE  FALSE          TRUE       x86_64
#> 27    TRUE     TRUE  FALSE          TRUE x86_64, ....
#> 28    TRUE     TRUE  FALSE          TRUE x86_64, ....
#> 29    TRUE    FALSE   TRUE          TRUE       x86_64
#> 30    TRUE     TRUE   TRUE          TRUE       x86_64
#> 31    TRUE     TRUE   TRUE          TRUE       x86_64
#> 32    TRUE     TRUE  FALSE          TRUE       x86_64
#> 33   FALSE     TRUE  FALSE          TRUE       x86_64
#> 34   FALSE     TRUE  FALSE          TRUE x86_64, ....
#> 35   FALSE     TRUE  FALSE          TRUE x86_64, ....
#> 36    TRUE     TRUE   TRUE          TRUE             
# }
```
