/*
 * Copyright (c) 2016-present, Yann Collet, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under both the BSD-style license (found in the
 * LICENSE file in the root directory of this source tree) and the GPLv2 (found
 * in the COPYING file in the root directory of this source tree).
 * You may select, at your option, one of the above-listed licenses.
 */

/* The objective of this example is to show of to compress multiple successive
* files
*  while preserving memory management.
*  All structures and buffers will be created only once,
*  and shared across all compression operations */

#include <stdlib.h>               // malloc, exit
#include <stdio.h>                // fprintf, perror, feof
#include <string.h>               // strerror
#include <errno.h>                // errno
#define ZSTD_STATIC_LINKING_ONLY  // streaming API defined as "experimental" for
                                  // the time being
#include <zstd.h>                 // presumes zstd library is installed
#include "utils.h"

typedef struct {
    void *buffIn;
    void *buffOut;
    size_t buffInSize;
    size_t buffOutSize;
    ZSTD_CStream *cstream;
} resources;

static resources
createResources_orDie()
{
    resources ress;
    ress.buffInSize = ZSTD_CStreamInSize(); /* can always read one full block */
    ress.buffOutSize =
        ZSTD_CStreamOutSize(); /* can always flush a full block */
    ress.buffIn = malloc_orDie(ress.buffInSize);
    ress.buffOut = malloc_orDie(ress.buffOutSize);
    ress.cstream = ZSTD_createCStream();
    if (ress.cstream == NULL) {
        fprintf(stderr, "ZSTD_createCStream() error \n");
        exit(10);
    }
    return ress;
}

static void
freeResources(resources ress)
{
    ZSTD_freeCStream(ress.cstream);
    free(ress.buffIn);
    free(ress.buffOut);
}

static void
compressFile_orDie(resources ress, const char *fname, const char *outName,
                   int cLevel)
{
    FILE *const fin = fopen_orDie(fname, "rb");
    FILE *const fout = fopen_orDie(outName, "wb");

    size_t const initResult = ZSTD_initCStream(ress.cstream, cLevel);
    if (ZSTD_isError(initResult)) {
        fprintf(stderr, "ZSTD_initCStream() error : %s \n",
                ZSTD_getErrorName(initResult));
        exit(11);
    }

    size_t read, toRead = ress.buffInSize;
    while ((read = fread_orDie(ress.buffIn, toRead, fin))) {
        ZSTD_inBuffer input = {ress.buffIn, read, 0};
        while (input.pos < input.size) {
            ZSTD_outBuffer output = {ress.buffOut, ress.buffOutSize, 0};
            toRead =
                ZSTD_compressStream(ress.cstream, &output,
                                    &input); /* toRead is guaranteed to be <=
                                                ZSTD_CStreamInSize() */
            if (ZSTD_isError(toRead)) {
                fprintf(stderr, "ZSTD_compressStream() error : %s \n",
                        ZSTD_getErrorName(toRead));
                exit(12);
            }
            if (toRead > ress.buffInSize)
                toRead =
                    ress.buffInSize; /* Safely handle when `buffInSize` is
                                        manually changed to a smaller value */
            fwrite_orDie(ress.buffOut, output.pos, fout);
        }
    }

    ZSTD_outBuffer output = {ress.buffOut, ress.buffOutSize, 0};
    size_t const remainingToFlush =
        ZSTD_endStream(ress.cstream, &output); /* close frame */
    if (remainingToFlush) {
        fprintf(stderr, "not fully flushed");
        exit(13);
    }
    fwrite_orDie(ress.buffOut, output.pos, fout);

    fclose_orDie(fout);
    fclose_orDie(fin);
}

int
main(int argc, const char **argv)
{
    const char *const exeName = argv[0];

    if (argc < 2) {
        printf("wrong arguments\n");
        printf("usage:\n");
        printf("%s FILE(s)\n", exeName);
        return 1;
    }

    resources const ress = createResources_orDie();
    void *ofnBuffer = NULL;
    size_t ofnbSize = 0;

    int argNb;
    for (argNb = 1; argNb < argc; argNb++) {
        const char *const ifn = argv[argNb];
        size_t const ifnSize = strlen(ifn);
        size_t const ofnSize = ifnSize + 5;
        if (ofnbSize <= ofnSize) {
            ofnbSize = ofnSize + 16;
            free(ofnBuffer);
            ofnBuffer = malloc_orDie(ofnbSize);
        }
        memset(ofnBuffer, 0, ofnSize);
        strcat(ofnBuffer, ifn);
        strcat(ofnBuffer, ".zst");
        compressFile_orDie(ress, ifn, ofnBuffer, 7);
    }

    freeResources(ress);
    free(ofnBuffer);

    printf("compressed %i files \n", argc - 1);

    return 0;
}
