"""
Cython-based file parsers.
"""
import numpy as np
from libc.stdio cimport fopen, fclose, getline, FILE, sscanf


def parse_gemfile(filename):
    """
    Cythonized gem logfile parser.

    Parameters
    ----------
    filename : bytes
        The filename to parse. Must be of type `bytes` -- use
        filename.encode('utf-8') if needed.

    Returns
    -------
    tuple of three aligned numpy arrays:

        - 2-d array of numeric values read from the file
        - 1-d array of characters indicating the line type
        - 1-d array of the millisecond value of the row
    """
    cdef char* fname = filename

    cdef FILE* cfile
    cfile = fopen(fname, "rb")
    if cfile == NULL:
        msg = "No such file or directory: '{}'".format(filename)
        raise FileNotFoundError(2, msg)

    cdef char * line = NULL
    cdef size_t line_length = 0
    cdef ssize_t read
    cdef char line_type = 0

    cdef int n_matched = 0
    # D placeholders
    cdef int DmsSamp = 0, ADC = 0
    # G placeholders
    cdef int msPPS = 0, msLag = 0, yr = 0, mo = 0, day = 0, hr = 0, mn = 0
    cdef double sec = 0, lat = 0, lon = 0
    # M placeholders
    cdef int ms = 0, maxLag = 0, minFree = 0, maxUsed = 0, maxOver = 0
    cdef int gpsFlag = 0, freeStack1 = 0, freeStackIdle = 0
    cdef double batt = 0, temp = 0, A2 = 0, A3 = 0

    # array to store parsed data
    n_row = 780000  # max number of rows to expect: 750000 + 15000 + 15000
    result_array = np.zeros((n_row, 11), dtype=np.double)
    # make a view for faster indexing.
    # see https://cython.readthedocs.io/en/latest/src/userguide/numpy_tutorial.html#efficient-indexing-with-memoryviews
    cdef double[:, :] view = result_array

    # 1-D array to store linetype (single chars)
    result_linetypes = np.zeros(n_row, dtype='c')
    cdef char[:] type_view = result_linetypes
    # 1-D array to store millis.
    # range is 0 to 2**13, so choose short int
    result_millis = np.zeros(n_row, dtype=np.int16)
    cdef short[:] millis_view = result_millis

    cdef Py_ssize_t line_number = 0
    # were this python 3.8 we could maybe use the walrus operator.  alas
    while True:
        read = getline(&line, &line_length, cfile)
        if read == -1:
            break

        line_type = line[0]
        if line_type == 68:  # ord('D') == 68
            # DmsSamp,ADC
            # D7780,-1
            n_matched = sscanf(line + 1, "%d,%d", &DmsSamp, &ADC)
            view[line_number, 0] = ADC
            millis_view[line_number] = DmsSamp

        elif line_type == 71:  # ord('G') == 71
            # G,msPPS,msLag,yr,mo,day,hr,min,sec,lat,lon
            # G,8171,70,2020,6,20,5,21,22.0,43.62226,-116.20594
            n_matched = sscanf(line + 2,
                               "%d,%d,%d,%d,%d,%d,%d,%lf,%lf,%lf",
                               &msPPS, &msLag, &yr, &mo, &day, &hr, &mn,
                               &sec, &lat, &lon)
            view[line_number, 0] = msLag
            view[line_number, 1] = yr
            view[line_number, 2] = mo
            view[line_number, 3] = day
            view[line_number, 4] = hr
            view[line_number, 5] = mn
            view[line_number, 6] = sec
            view[line_number, 7] = lat
            view[line_number, 8] = lon
            millis_view[line_number] = msPPS

        elif line_type == 77:  # ord('M') == 77
            # M,ms,batt(V),temp(C),A2,A3,maxLag,minFree,maxUsed,maxOver,
            # gpsFlag,freeStack1,freeStackIdle
            # M,8001,3.02,22.1,1.412,2.052,94,66,9,0,0,57,86
            n_matched = sscanf(line + 2,
                               "%d,%lf,%lf,%lf,%lf,%d,%d,%d,%d,%d,%d,%d",
                               &ms, &batt, &temp, &A2, &A3, &maxLag,
                               &minFree, &maxUsed, &maxOver, &gpsFlag,
                               &freeStack1, &freeStackIdle)
            view[line_number, 0] = batt
            view[line_number, 1] = temp
            view[line_number, 2] = A2
            view[line_number, 3] = A3
            view[line_number, 4] = maxLag
            view[line_number, 5] = minFree
            view[line_number, 6] = maxUsed
            view[line_number, 7] = maxOver
            view[line_number, 8] = gpsFlag
            view[line_number, 9] = freeStack1
            view[line_number, 10] = freeStackIdle
            millis_view[line_number] = ms
        else:
            continue

        type_view[line_number] = line_type
        line_number += 1

    fclose(cfile)

    return (
        result_array[:line_number, :],
        result_linetypes[:line_number],
        result_millis[:line_number],
    )
