/*********************************************************************
 * bfs                                                               *
 * Copyright (C) 2015 Tavian Barnes <tavianator@tavianator.com>      *
 *                                                                   *
 * This program is free software. It comes without any warranty, to  *
 * the extent permitted by applicable law. You can redistribute it   *
 * and/or modify it under the terms of the Do What The Fuck You Want *
 * To Public License, Version 2, as published by Sam Hocevar. See    *
 * the COPYING file or http://www.wtfpl.net/ for more details.       *
 *********************************************************************/

#ifndef BFS_BFTW_H
#define BFS_BFTW_H

#include <sys/stat.h>

/**
 * Data about the current file for the bftw() callback.
 */
struct BFTW {
        /** A stat() buffer; may be NULL if no stat() call was needed. */
	const struct stat *statbuf;
	/** A typeflag value (see below). */
	int typeflag;
	/** The string offset of the filename in the path. */
	int base;
	/** The depth of this file in the walk. */
	int level;
	/** The errno that occurred, if typeflag == BFTW_ERROR. */
	int error;
};

/**
 * Callback function type for bftw().
 *
 * @param fpath
 *         The path to the encountered file.
 * @param ftwbuf
 *         Additional data about the current file.
 * @param ptr
 *         The pointer passed to bftw().
 * @return
 *         An action value (see below).
 */
typedef int bftw_fn(const char *fpath, const struct BFTW *ftwbuf, void *ptr);

/**
 * Breadth First Tree Walk (or Better File Tree Walk).
 *
 * Like ftw(3) and nftw(3), this function walks a directory tree recursively,
 * and invokes a callback for each path it encounters.  However, bftw() operates
 * breadth-first.
 *
 * @param path
 *         The starting path.
 * @param fn
 *         The callback to invoke.
 * @param nopenfd
 *         The maximum number of file descriptors to keep open.
 * @param flags
 *         Flags that control bftw() behavior (see below).
 * @param ptr
 *         A generic pointer which is passed to fn().
 * @return
 *         0 on success, or -1 on failure.
 */
int bftw(const char *path, bftw_fn *fn, int nopenfd, int flags, void *ptr);

/** typeflag: Block device. */
#define BFTW_BLK      0
/** typeflag: Character device. */
#define BFTW_CHR      1
/** typeflag: Directory. */
#define BFTW_DIR      2
/** typeflag: Pipe. */
#define BFTW_FIFO     3
/** typeflag: Symbolic link. */
#define BFTW_LNK      4
/** typeflag: Regular file. */
#define BFTW_REG      5
/** typeflag: Socket. */
#define BFTW_SOCK     6
/** typeflag: Unknown type. */
#define BFTW_UNKNOWN  7
/** typeflag: An error occurred for this file. */
#define BFTW_ERROR    8

/** action: Keep walking. */
#define BFTW_CONTINUE       0
/** action: Skip this path's siblings. */
#define BFTW_SKIP_SIBLINGS  1
/** action: Skip this path's children. */
#define BFTW_SKIP_SUBTREE   2
/** action: Stop walking. */
#define BFTW_STOP           3

/** flag: stat() each encountered file. */
#define BFTW_STAT     (1 << 0)
/** flag: Attempt to recover from encountered errors. */
#define BFTW_RECOVER  (1 << 1)

#endif // BFS_BFTW_H
