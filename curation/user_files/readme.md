# User files

This folder defines the structure and location of the files required by curation forms and 
scripts. This directory can be directly mounted in the curation_forms Docker container and 
the required files can be copied in the respective directories or a different volume can be
mounted provided that it follows the same directory structure. Readme files in subdirectories
define the properties of each required file and should have the following format:

* **File name:** the file name expected by forms and scripts - e.g., `file_name.csv` 
* **Description:** Describes the file
* **File format:** 

    The expected format - e.g. space delimited values (with header)

    - NAME: person name
    - JOB: job

    Example:
    ```
    NAME TITLE
    Mario plumber
    Luigi plumber
    ```
  
* **Required by:** List of cgis or scripts that require the file
* **File maintainer:** person in charge of this file