The BaseCommands.sh are created in a folder called BaseOptions_output
The NewCommands.sh outputs are created in a folder NewOptions_output
These two are taken as inputs to autoscript to generate the md5s and compare them

STEPS:
> Enter docker in an older ffmpeg build, run the BaseCommands.sh (or NewCommands.sh) Based on which commit is being used.
> exit, docker , and renter from the new ffmpeg build you need to compare with and run the NewCommands.sh file
>Run the autoscript.sh (with parameters as  Base outputs folder and New outputs folder)


------------------
 ENV USED FOR TEST
------------------

The Base commands are commands for ffmpeg at the following commits:
ma35 repo (commit):
commit 18fc41ba92f27e75e204142b9804dd49b6a6fc1b (HEAD -> develop, tag: nightly/230117, tag: nightly/230116, tag: nightly/230115, tag: nightly/230114, tag: interim/230116_2306, tag: interim/230116_2122, tag: interim/230116_1956, tag: interim/230116_1639, origin/pre_alpha, origin/develop, origin/HEAD)
Author: Jim Kuhn <kuhn@xilinx.com>
Date:   Fri Jan 13 16:48:25 2023 -0500

    VID-1835: Update demo image / scripts

#ma35_ffmpeg (commit):
commit e1eca3a7aebaa1132dc07eadca7222097b1018bc (HEAD -> develop, tag: nightly/230117, tag: nightly/230116, tag: nightly/230115, tag: nightly/230114, tag: interim/230116_2306, tag: interim/230116_2122, tag: interim/230116_1956, tag: interim/230116_1639, origin/pre_alpha, origin/develop, origin/HEAD)
Merge: e4e0df4 335395f
Author: Rohit Consul <rohitco@xilinx.com>
Date:   Fri Jan 13 12:31:05 2023 -0800

    Merge pull request #33 from cn1247/set_the_init_map_info

    set the init map info

The New Commands work for ffmpeg and ma35 with the below mentioned or later commits:

#ma35 (commit)
commit d6ba01ad4e36f7a848efa4b16ca4cd43af1bbca0 (HEAD -> develop, tag: nightly/230118, tag: interim/230118_2152, origin/develop, origin/HEAD)
Merge: 0d57771 6101f77
Author: kuhn-xilinx <67280187+kuhn-xilinx@users.noreply.github.com>
Date:   Wed Jan 18 11:01:59 2023 -0500

    Merge pull request #16 from zmotiXilinx/develop

    VID-0000: add link to failed build in slack notification


