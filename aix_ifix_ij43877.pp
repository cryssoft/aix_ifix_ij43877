#
#  2023/02/24 - cp - Double-checking revisions/spins against a new package of
#		kernel_fix5.
#
#  2023/02/27 - cp - Added the new logic based on the aix_ifix_package custom
#		fact so we can only apply this ifix to machines that need it.
#
#-------------------------------------------------------------------------------
#
#  From Advisory.asc:
#
#    For pfcdd kernel extension:
#
#    AIX Level APAR     Availability  SP        KEY         PRODUCT(S)
#    -----------------------------------------------------------------
#    7.1.5     IJ43980  **            SP11      key_w_apar  pfcdd
#    7.2.5     IJ43877  **            SP06      key_w_apar  pfcdd
#    7.3.0     IJ43893  **            SP03      key_w_apar  pfcdd
#
#    VIOS Level APAR    Availability  SP        KEY         PRODUCT(S)
#    -----------------------------------------------------------------
#    3.1.2      IJ44116 **            3.1.2.50  key_w_apar  pfcdd
#    3.1.3      IJ43877 **            3.1.3.30  key_w_apar  pfcdd
#|   3.1.4      IJ43877 **            3.1.4.20  key_w_apar  pfcdd
#
#    For pfcdd kernel extension:
#
#    AIX Level  Interim Fix (*.Z)         KEY        PRODUCT(S)
#    ----------------------------------------------------------
#    7.1.5.8    IJ43980sAa.221024.epkg.Z  key_w_fix  pfcdd
#    7.1.5.9    IJ43980sAa.221024.epkg.Z  key_w_fix  pfcdd
#    7.1.5.10   IJ43980sAa.221024.epkg.Z  key_w_fix  pfcdd
#    7.2.5.2    IJ44116s2a.221102.epkg.Z  key_w_fix  pfcdd
#    7.2.5.3    IJ43877s3a.221025.epkg.Z  key_w_fix  pfcdd
#    7.2.5.4    IJ43877s4a.221017.epkg.Z  key_w_fix  pfcdd
#|   7.2.5.5    IJ43877s5a.230123.epkg.Z  key_w_fix  pfcdd
#    7.3.0.1    IJ43893s1a.221027.epkg.Z  key_w_fix  pfcdd
#    7.3.0.2    IJ43893s2a.221018.epkg.Z  key_w_fix  pfcdd
#
#    Please note that the above table refers to AIX TL/SP level as
#    opposed to fileset level, i.e., 7.2.5.4 is AIX 7200-05-04.
#
#    VIOS Level  Interim Fix (*.Z)         KEY        PRODUCT(S)
#    -----------------------------------------------------------
#    3.1.2.21    IJ44116s2a.221102.epkg.Z  key_w_fix  pfcdd
#    3.1.2.30    IJ44116s2a.221102.epkg.Z  key_w_fix  pfcdd
#    3.1.2.40    IJ44116s2a.221102.epkg.Z  key_w_fix  pfcdd
#    3.1.3.10    IJ43877s3a.221025.epkg.Z  key_w_fix  pfcdd
#    3.1.3.14    IJ43877s3a.221025.epkg.Z  key_w_fix  pfcdd
#    3.1.3.21    IJ43877s4a.221017.epkg.Z  key_w_fix  pfcdd
#|   3.1.4.10    IJ43877s5a.230123.epkg.Z  key_w_fix  pfcdd
#
#-------------------------------------------------------------------------------
#
class aix_ifix_ij43877 {

    #  Make sure we can get to the ::staging module (deprecated ?)
    include ::staging

    #  This only applies to AIX and VIOS 
    if ($::facts['osfamily'] == 'AIX') {

        #  Set the ifix ID up here to be used later in various names
        $ifixName = 'IJ43877'

        #  Make sure we create/manage the ifix staging directory
        require aix_file_opt_ifixes

        #
        #  For now, we're skipping anything that reads as a VIO server.
        #  We have no matching versions of this ifix / VIOS level installed.
        #
        unless ($::facts['aix_vios']['is_vios']) {

            #  This is an optional package we don't have everywhere
            if ('bos.pfcdd.rte' in $::facts['aix_ifix_package'].keys) {

                #
                #  Friggin' IBM...  The ifix ID that we find and capture in the fact has the
                #  suffix allready applied.
                #
                if ($::facts['kernelrelease'] == '7200-05-03-2148') {
                    $ifixSuffix = 's3a'
                    $ifixBuildDate = '221025'
                }
                else {
                    if ($::facts['kernelrelease'] == '7200-05-04-2220') {
                        $ifixSuffix = 's4a'
                        $ifixBuildDate = '221017'
                    }
                    else {
                        if ($::facts['kernelrelease'] == '7200-05-05-2246') {
                            $ifixSuffix = 's5a'
                            $ifixBuildDate = '230123'
                        }
                        else {
                            $ifixSuffix = 'unknown'
                            $ifixBuildDate = 'unknown'
                        }
                    }
                }
            }
            else {
                $ifixSuffix = 'unknown'
                $ifixBuildDate = 'unknown'
            }

        }

        #
        #  This one applies equally to AIX and VIOS in our environment, so deal with VIOS as well.
        #
        else {
            if ($::facts['aix_vios']['version'] == '3.1.3.14') {
                $ifixSuffix = 's3a'
                $ifixBuildDate = '221025'
            }
            else {
                if ($::facts['aix_vios']['version'] == '3.1.4.10') {
                    $ifixSuffix = 's5a'
                    $ifixBuildDate = '230123'
                }
                else {
                    $ifixSuffix = 'unknown'
                    $ifixBuildDate = 'unknown'
                }
            }
        }

        #================================================================================
        #  Re-factor this code out of the AIX-only branch, since it applies to both.
        #================================================================================

        #  If we set our $ifixSuffix and $ifixBuildDate, we'll continue
        if (($ifixSuffix != 'unknown') and ($ifixBuildDate != 'unknown')) {

            #  Add the name and suffix to make something we can find in the fact
            $ifixFullName = "${ifixName}${ifixSuffix}"

            #  Don't bother with this if it's already showing up installed
            unless ($ifixFullName in $::facts['aix_ifix']['hash'].keys) {
 
                #  Build up the complete name of the ifix staging source and target
                $ifixStagingSource = "puppet:///modules/aix_ifix_ij43877/${ifixName}${ifixSuffix}.${ifixBuildDate}.epkg.Z"
                $ifixStagingTarget = "/opt/ifixes/${ifixName}${ifixSuffix}.${ifixBuildDate}.epkg.Z"

                #  Stage it
                staging::file { "$ifixStagingSource" :
                    source  => "$ifixStagingSource",
                    target  => "$ifixStagingTarget",
                    before  => Exec["emgr-install-${ifixName}"],
                }

                #  GAG!  Use an exec resource to install it, since we have no other option yet
                exec { "emgr-install-${ifixName}":
                    path     => '/bin:/sbin:/usr/bin:/usr/sbin:/etc',
                    command  => "/usr/sbin/emgr -e $ifixStagingTarget",
                    unless   => "/usr/sbin/emgr -l -L $ifixFullName",
                }

                #  Explicitly define the dependency relationships between our resources
                File['/opt/ifixes']->Staging::File["$ifixStagingSource"]->Exec["emgr-install-${ifixName}"]

            }

        }

    }

}
