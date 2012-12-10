# Note: when executed in the build dir, then CMAKE_CURRENT_SOURCE_DIR is the
# build dir.
file( COPY setup.py configure.py bright data DESTINATION "${CMAKE_ARGV3}"
    FILES_MATCHING PATTERN "*.py" 
                   PATTERN "*.pyw" 
                   PATTERN "*.csv" 
                   PATTERN "*.txt" 
                   PATTERN "*.html" 
                   PATTERN "*.h5" 
                   PATTERN "*.pxi")
