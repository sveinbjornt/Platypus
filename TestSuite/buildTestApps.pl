#!/bin/sh


PLATYPUS_CMD=build/Deployment/platypus

# Clean out old builds and create directory for the test apps
rm -Rf build/Deployment/TestApps
mkdir -p build/Deployment/TestApps


########## DROPLET TEST APPS ################

# Shell droplet w. Text Window
$PLATYPUS_CMD -DRl -a 'Shell-Droplet-PrintFiles-TextWindow' -o 'Text Window' -p '/bin/sh' -X '*' -T '****|fold'  -c 'TestSuite/Shell-Droplet-PrintFiles.sh' 'build/Deployment/TestApps/Shell-Droplet-PrintFiles-TextWindow.app'

# Perl droplet w. Text Window
$PLATYPUS_CMD -DRl -a 'Perl-Droplet-PrintFiles-TextWindow' -o 'Text Window'  -p '/usr/bin/perl' -X '*' -T '****|fold' -c 'TestSuite/Perl-Droplet-PrintFiles.pl' 'build/Deployment/TestApps/Perl-Droplet-PrintFiles-TextWindow.app'

# Shell droplet w. Progress Bar
$PLATYPUS_CMD -DRl -a 'Shell-Droplet-PrintFiles-ProgressBar' -o 'Progress Bar' -p '/bin/sh' -X '*' -T '****|fold'  -c 'TestSuite/Shell-Droplet-PrintFiles.sh' 'build/Deployment/TestApps/Shell-Droplet-PrintFiles-ProgressBar.app'

# Perl droplet w. Progress Bar
$PLATYPUS_CMD -DRl -a 'Perl-Droplet-PrintFiles-ProgressBar' -o 'Progress Bar'  -p '/usr/bin/perl' -X '*' -T '****|fold' -c 'TestSuite/Perl-Droplet-PrintFiles.pl' 'build/Deployment/TestApps/Perl-Droplet-PrintFiles-ProgressBar.app'

# Perl droplet w. Web Output
$PLATYPUS_CMD -DRl -a 'Perl-Droplet-PrintFiles-WebOutput' -o 'Web View' -p '/usr/bin/perl' -X '*' -T '****|fold' -c 'TestSuite/Perl-Droplet-PrintFiles-WebOutput.pl' 'build/Deployment/TestApps/Perl-Droplet-PrintFiles-WebOutput.app'


######### COLOUR TEST #########

# Test color and font in text window
$PLATYPUS_CMD -Rl -a 'Shell-HelloWorld' -o 'Text Window' -p '/bin/sh' -g '#02ff00'  -b '#ff243c' -n 'Helvetica 18' -c 'TestSuite/Shell-HelloWorld.sh' 'build/Deployment/TestApps/Shell-ColourTest-TextWindow.app'

# Test color and font in progress bar
$PLATYPUS_CMD -Rl -a 'Shell-HelloWorld' -o 'Progress Bar' -p '/bin/sh' -g '#02ff00'  -b '#ff243c' -n 'Helvetica 18' -c 'TestSuite/Shell-HelloWorld.sh' 'build/Deployment/TestApps/Shell-ColourTest-ProgressBar.app'

######### OUTPUT LENGTH TEST ############

$PLATYPUS_CMD -Rl -a 'Perl-OutputLengthTest' -o 'Text Window' -p '/usr/bin/perl' -c 'TestSuite/Perl-OutputLengthTest.pl' 'build/Deployment/TestApps/Perl-OutputLengthTest.app'

######### SECURE SCRIPT TEST #######

# Secure basic hello world shell script
$PLATYPUS_CMD -RSl -a 'Shell-SecureHelloWorld' -o 'Progress Bar' -p '/bin/sh' -g '#02ff00'  -b '#ff243c' -n 'Helvetica 18' -c 'TestSuite/Shell-HelloWorld.sh' 'build/Deployment/TestApps/Shell-SecureHelloWorld-ProgressBar.app'

# Secure perl droplet w. Text Window
$PLATYPUS_CMD -DRSl -a 'Perl-SecureDroplet-PrintFiles-TextWindow' -o 'Text Window'  -p '/usr/bin/perl' -X '*' -T '****|fold' -c 'TestSuite/Perl-Droplet-PrintFiles.pl' 'build/Deployment/TestApps/Perl-SecureDroplet-PrintFiles-TextWindow.app'

######### ADMIN PRIVILEGES ##########

# Admin hello world
$PLATYPUS_CMD -ARl -a 'Shell-HelloWorld-Admin' -o 'Text Window' -p '/bin/sh' -g '#02ff00'  -b '#ff243c' -n 'Helvetica 18' -c 'TestSuite/Shell-HelloWorld.sh' 'build/Deployment/TestApps/Shell-HelloWorld-Admin.app'
# Admin secure hello world
$PLATYPUS_CMD -ARSl -a 'Shell-HelloWorld-Admin' -o 'Text Window' -p '/bin/sh' -g '#02ff00'  -b '#ff243c' -n 'Helvetica 18' -c 'TestSuite/Shell-HelloWorld.sh' 'build/Deployment/TestApps/Shell-HelloWorld-Admin-Secure.app'
# Perl droplet w. Text Window
$PLATYPUS_CMD -ADRl -a 'Perl-Droplet-Admin' -o 'Text Window'  -p '/usr/bin/perl' -X '*' -T '****|fold' -c 'TestSuite/Perl-Droplet-PrintFiles.pl' 'build/Deployment/TestApps/Perl-Droplet-Admin.app'
# Perl droplet w. Text Window
$PLATYPUS_CMD -ADRSl -a 'Perl-Droplet-Admin-Secure' -o 'Text Window'  -p '/usr/bin/perl' -X '*' -T '****|fold' -c 'TestSuite/Perl-Droplet-PrintFiles.pl' 'build/Deployment/TestApps/Perl-Droplet-Admin-Secure.app'

