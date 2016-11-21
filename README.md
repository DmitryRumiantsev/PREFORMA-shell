# PREFORMA-shell

This is a shell script that coordinates the behaviour of different conformance checkers from PREFORMA project (http://www.preforma-project.eu/).
Supported checkers: 
- veraPDF
- DPF manager
- MediaConch

IMPORTANT: in order for this script to work with veraPDF, you should execute the follownig command: sudo ln -s <path to verpdf shellscript on your PC> / usr/bin/verapdf. This will change it future.

At the moment it cofirms which of the supported checkers (or the checkers explicitly specified by user) are callable, then associates each file in a specified folder with one of the checkers and performs basic validation. 

Syntax:
./register_and_associate.sh [OPTIONS] 

Options:

-p: path to the directory (or a single file) where the files you want to validate are contained. Can be absolute or relative.

-l: list of conformance checkers and their associated mimetypes that you want to specify explicilty. Their callability would not be checked.
  The syntax is "verapdf: application/pdf; dpf-manager: image/tiff,image/tiff-fx".
  
-o: list of output directories for the reports from one or several supported checkers. By default, the reports are stored in "reports_verapdf,reports_mediaconch, reports_dpf_manager" in current working directory.
The syntax is "verapdf: reports_vera; dpf-manager: //home/user/reports_dpf".
