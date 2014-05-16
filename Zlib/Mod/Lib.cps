MODULE ZlibLib ["zlibwapi"];
IMPORT C := CApiTypes;

CONST
   
   VERSION*         = '1.2.8';
   VERNUM*          = 01280H;
   VER_MAJOR*       = 1;
   VER_MINOR*       = 2;
   VER_REVISION*    = 8;
   VER_SUBREVISION* = 0;

   (* constants *)

   NO_FLUSH*      = 0;
   PARTIAL_FLUSH* = 1;
   SYNC_FLUSH*    = 2;
   FULL_FLUSH*    = 3;
   FINISH*        = 4;
   BLOCK*         = 5;
   TREES*         = 6;

   (* Allowed flush values; see deflate() and inflate() below for details *)

   OK*            =  0;
   STREAM_END*    =  1;
   NEED_DICT*     =  2;
   ERRNO*         = -1;
   STREAM_ERROR*  = -2;
   DATA_ERROR*    = -3;
   MEM_ERROR*     = -4;
   BUF_ERROR*     = -5;
   VERSION_ERROR* = -6;

   (* Return codes for the compression/decompression PROCEDURE [ccall]s. Negative values
    * are errors, positive values are used for special but normal events.
    *)

   NO_COMPRESSION*       =  0;
   BEST_SPEED*           =  1;
   BEST_COMPRESSION*     =  9;
   DEFAULT_COMPRESSION*  = -1;
   (* compression levels *)

   FILTERED*         = 1;
   HUFFMAN_ONLY*     = 2;
   RLE*              = 3;
   FIXED*            = 4;
   DEFAULT_STRATEGY* = 0;
   (* compression strategy; see deflateInit2() below for details *)

   BINARY*  = 0;
   TEXT*    = 1;
   ASCII*   = TEXT; (* for compatibility with 1.2.2 and earlier *)
   UNKNOWN* = 2;
   (* Possible values of the data_type field (though see inflate()) *)

   DEFLATED* = 8;
   (* The deflate compression method (the only one supported in this version) *)

   NULL* = 0;  (* for initializing zalloc, zfree, opaque *)

TYPE
   PtrChar*  = C.p_char;
   PtrWChar* = C.p_wchar;
   Int*      = C.signed_int; 
   UInt*     = C.unsigned_int;
   PtrVoid*  = C.p_void;
   Pointer   = C.p_void;
   ULong*    = C.unsigned_long_int;
   Long*     = C.signed_long_int;
   Offset*   = INTEGER;

   AllocFunc = PROCEDURE [ccall] (opaque: PtrVoid; items, size: UInt): INTEGER;
   FreeFunc = PROCEDURE [ccall] (opaque: PtrVoid; items, size: UInt);

   InFunc = PROCEDURE [ccall] (in_desc: INTEGER; VAR c: PtrChar): UInt;
   OutFunc = PROCEDURE [ccall] (out_desc: INTEGER; c: PtrChar; i: UInt): Int;

   PtrStream = POINTER TO Stream;
   Stream = RECORD
      next_in  : PtrChar; (* next input byte *)
      avail_in : UInt;    (* number of bytes available at next_in *)
      total_in : ULong;   (* total number of input bytes read so far *)

      next_out : PtrChar; (* next output byte should be put there *)
      avail_out: UInt;    (* remaining free space at next_out *)
      total_out: ULong;   (* total number of bytes output so far *)

      msg      : PtrChar; (* last error message, NULL if no error *)
      state    : PtrVoid; (* not visible by applications *)

      zalloc: AllocFunc;  (* used to allocate the internal state *)
      zfree: FreeFunc;    (* used to free the internal state *)
      opaque: PtrVoid;    (* private data object passed to zalloc and zfree *)

      data_type: Int;     (* best guess about the data type: binary or text *)
      adler: ULong;       (* adler32 value of the uncompressed data *)
      reserved: ULong;    (* reserved for future use *)
   END;

   gz_headerp = POINTER TO gz_header;
   gz_header = RECORD
      text     : Int;     (* true if compressed data believed to be text *)
      time     : ULong;   (* modification time *)
      xflags   : Int;     (* extra flags (not used when writing a gzip file) *)
      os       : Int;     (* operating system *)
      extra    : PtrChar; (* INTEGER to extra field or NULL if none *)
      extra_len: UInt;    (* extra field length (valid if extra != NULL) *)
      extra_max: UInt;    (* space at extra (only when reading header) *)
      name     : PtrChar; (* INTEGER to zero-terminated file name or NULL *)
      name_max : UInt;    (* space at name (only when reading header) *)
      comment  : PtrChar; (* INTEGER to zero-terminated comment or NULL *)
      comm_max : UInt;    (* space at comment (only when reading header) *)
      hcrc     : Int;     (* true if there was or will be a header crc *)
      done     : Int;     (* true when done reading gzip header (not used when writing a gzip file) *)
   END;
   
PROCEDURE [ccall] zlibVersion ["zlibVersion"] (): PtrChar;
(* 
     The application can compare zlibVersion and ZLIB_VERSION for consistency.
   If the first character differs, the library code actually used is not
   compatible with the zlib.h header file used by the application.  This check
   is automatically made by deflateInit and inflateInit.
*)
PROCEDURE [ccall] deflateInit_ ["deflateInit_"] (VAR strm: PtrStream; level: Int; version: PtrChar; stream_size: Int): Int;
(*
     Initializes the internal stream state for compression.  The fields
   zalloc, zfree and opaque must be initialized before by the caller.  If
   zalloc and zfree are set to NULL, deflateInit updates them to use default
   allocation functions.

     The compression level must be DEFAULT_COMPRESSION, or between 0 and 9:
   1 gives best speed, 9 gives best compression, 0 gives no compression at all
   (the input data is simply copied a block at a time).  DEFAULT_COMPRESSION
   requests a default compromise between speed and compression (currently
   equivalent to level 6).

     deflateInit returns OK if success, MEM_ERROR if there was not enough
   memory, STREAM_ERROR if level is not a valid compression level, or
   VERSION_ERROR if the zlib library version (zlib_version) is incompatible
   with the version assumed by the caller (ZLIB_VERSION).  msg is set to null
   if there is no error message.  deflateInit does not perform any compression:
   this will be done by deflate().
*)
PROCEDURE [ccall] deflate ["deflate"] (VAR strm: PtrStream; flush: Int): Int;
(*
     deflate compresses as much data as possible, and stops when the input
   buffer becomes empty or the output buffer becomes full.  It may introduce
   some output latency (reading input without producing any output) except when
   forced to flush.
 
     The detailed semantics are as follows.  deflate performs one or both of the
   following actions:
 
   - Compress more input starting at next_in and update next_in and avail_in
     accordingly.  If not all input can be processed (because there is not
     enough room in the output buffer), next_in and avail_in are updated and
     processing will resume at this point for the next call of deflate().
 
   - Provide more output starting at next_out and update next_out and avail_out
     accordingly.  This action is forced if the parameter flush is non zero.
     Forcing flush frequently degrades the compression ratio, so this parameter
     should be set only when necessary (in interactive applications).  Some
     output may be provided even if flush is not set.
 
     Before the call of deflate(), the application should ensure that at least
   one of the actions is possible, by providing more input and/or consuming more
   output, and updating avail_in or avail_out accordingly; avail_out should
   never be zero before the call.  The application can consume the compressed
   output when it wants, for example when the output buffer is full (avail_out
   == 0), or after each call of deflate().  If deflate returns OK and with
   zero avail_out, it must be called again after making room in the output
   buffer because there might be more output pending.
 
     Normally the parameter flush is set to NO_FLUSH, which allows deflate to
   decide how much data to accumulate before producing output, in order to
   maximize compression.
 
     If the parameter flush is set to SYNC_FLUSH, all pending output is
   flushed to the output buffer and the output is aligned on a byte boundary, so
   that the decompressor can get all input data available so far.  (In
   particular avail_in is zero after the call if enough output space has been
   provided before the call.) Flushing may degrade compression for some
   compression algorithms and so it should be used only when necessary.  This
   completes the current deflate block and follows it with an empty stored block
   that is three bits plus filler bits to the next byte, followed by four bytes
   (00 00 ff ff).
 
     If flush is set to PARTIAL_FLUSH, all pending output is flushed to the
   output buffer, but the output is not aligned to a byte boundary.  All of the
   input data so far will be available to the decompressor, as for SYNC_FLUSH.
   This completes the current deflate block and follows it with an empty fixed
   codes block that is 10 bits long.  This assures that enough bytes are output
   in order for the decompressor to finish the block before the empty fixed code
   block.
 
     If flush is set to BLOCK, a deflate block is completed and emitted, as
   for SYNC_FLUSH, but the output is not aligned on a byte boundary, and up to
   seven bits of the current block are held to be written as the next byte after
   the next deflate block is completed.  In this case, the decompressor may not
   be provided enough bits at this point in order to complete decompression of
   the data provided so far to the compressor.  It may need to wait for the next
   block to be emitted.  This is for advanced applications that need to control
   the emission of deflate blocks.
 
     If flush is set to FULL_FLUSH, all output is flushed as with
   SYNC_FLUSH, and the compression state is reset so that decompression can
   restart from this point if previous compressed data has been damaged or if
   random access is desired.  Using FULL_FLUSH too often can seriously degrade
   compression.
 
     If deflate returns with avail_out == 0, this function must be called again
   with the same value of the flush parameter and more output space (updated
   avail_out), until the flush is complete (deflate returns with non-zero
   avail_out).  In the case of a FULL_FLUSH or SYNC_FLUSH, make sure that
   avail_out is greater than six to avoid repeated flush markers due to
   avail_out == 0 on return.
 
     If the parameter flush is set to FINISH, pending input is processed,
   pending output is flushed and deflate returns with STREAM_END if there was
   enough output space; if deflate returns with OK, this function must be
   called again with FINISH and more output space (updated avail_out) but no
   more input data, until it returns with STREAM_END or an error.  After
   deflate has returned STREAM_END, the only possible operations on the stream
   are deflateReset or deflateEnd.
 
     FINISH can be used immediately after deflateInit if all the compression
   is to be done in a single step.  In this case, avail_out must be at least the
   value returned by deflateBound (see below).  Then deflate is guaranteed to
   return STREAM_END.  If not enough output space is provided, deflate will
   not return STREAM_END, and it must be called again as described above.
 
     deflate() sets strm->adler to the adler32 checksum of all input read
   so far (that is, total_in bytes).
 
     deflate() may update strm->data_type if it can make a good guess about
   the input data type (BINARY or TEXT).  In doubt, the data is considered
   binary.  This field is only for information purposes and does not affect the
   compression algorithm in any manner.
 
     deflate() returns OK if some progress has been made (more input
   processed or more output produced), STREAM_END if all input has been
   consumed and all output has been produced (only when flush is set to
   FINISH), STREAM_ERROR if the stream state was inconsistent (for example
   if next_in or next_out was NULL), BUF_ERROR if no progress is possible
   (for example avail_in or avail_out was zero).  Note that BUF_ERROR is not
   fatal, and deflate() can be called again with more input and more output
   space to continue compressing.
*)

PROCEDURE [ccall] deflateEnd ["deflateEnd"] (VAR strm: PtrStream): Int;
(*
     All dynamically allocated data structures for this stream are freed.
   This function discards any unprocessed input and does not flush any pending
   output.

     deflateEnd returns OK if success, STREAM_ERROR if the
   stream state was inconsistent, DATA_ERROR if the stream was freed
   prematurely (some input or output was discarded).  In the error case, msg
   may be set but then points to a static string (which must not be
   deallocated).
*)
PROCEDURE [ccall] inflateInit_ ["inflateInit_"] (VAR strm: PtrStream; version: PtrChar; stream_size: Int): Int;
(*
     Initializes the internal stream state for decompression.  The fields
   next_in, avail_in, zalloc, zfree and opaque must be initialized before by
   the caller.  If next_in is not NULL and avail_in is large enough (the
   exact value depends on the compression method), inflateInit determines the
   compression method from the zlib header and allocates all data structures
   accordingly; otherwise the allocation will be deferred to the first call of
   inflate.  If zalloc and zfree are set to NULL, inflateInit updates them to
   use default allocation functions.

     inflateInit returns OK if success, MEM_ERROR if there was not enough
   memory, VERSION_ERROR if the zlib library version is incompatible with the
   version assumed by the caller, or STREAM_ERROR if the parameters are
   invalid, such as a null pointer to the structure.  msg is set to null if
   there is no error message.  inflateInit does not perform any decompression
   apart from possibly reading the zlib header if present: actual decompression
   will be done by inflate().  (So next_in and avail_in may be modified, but
   next_out and avail_out are unused and unchanged.) The current implementation
   of inflateInit() does not process any header information -- that is deferred
   until inflate() is called.
*)
PROCEDURE [ccall] inflate ["inflate"] (VAR strm: PtrStream; flush: Int): Int;
(*
     inflate decompresses as much data as possible, and stops when the input
   buffer becomes empty or the output buffer becomes full.  It may introduce
   some output latency (reading input without producing any output) except when
   forced to flush.
 
   The detailed semantics are as follows.  inflate performs one or both of the
   following actions:
 
   - Decompress more input starting at next_in and update next_in and avail_in
     accordingly.  If not all input can be processed (because there is not
     enough room in the output buffer), next_in is updated and processing will
     resume at this point for the next call of inflate().
 
   - Provide more output starting at next_out and update next_out and avail_out
     accordingly.  inflate() provides as much output as possible, until there is
     no more input data or no more space in the output buffer (see below about
     the flush parameter).
 
     Before the call of inflate(), the application should ensure that at least
   one of the actions is possible, by providing more input and/or consuming more
   output, and updating the next_* and avail_* values accordingly.  The
   application can consume the uncompressed output when it wants, for example
   when the output buffer is full (avail_out == 0), or after each call of
   inflate().  If inflate returns OK and with zero avail_out, it must be
   called again after making room in the output buffer because there might be
   more output pending.
 
     The flush parameter of inflate() can be NO_FLUSH, SYNC_FLUSH, FINISH,
   BLOCK, or TREES.  SYNC_FLUSH requests that inflate() flush as much
   output as possible to the output buffer.  BLOCK requests that inflate()
   stop if and when it gets to the next deflate block boundary.  When decoding
   the zlib or gzip format, this will cause inflate() to return immediately
   after the header and before the first block.  When doing a raw inflate,
   inflate() will go ahead and process the first block, and will return when it
   gets to the end of that block, or when it runs out of data.
 
     The BLOCK option assists in appending to or combining deflate streams.
   Also to assist in this, on return inflate() will set strm->data_type to the
   number of unused bits in the last byte taken from strm->next_in, plus 64 if
   inflate() is currently decoding the last block in the deflate stream, plus
   128 if inflate() returned immediately after decoding an end-of-block code or
   decoding the complete header up to just before the first byte of the deflate
   stream.  The end-of-block will not be indicated until all of the uncompressed
   data from that block has been written to strm->next_out.  The number of
   unused bits may in general be greater than seven, except when bit 7 of
   data_type is set, in which case the number of unused bits will be less than
   eight.  data_type is set as noted here every time inflate() returns for all
   flush options, and so can be used to determine the amount of currently
   consumed input in bits.
 
     The TREES option behaves as BLOCK does, but it also returns when the
   end of each deflate block header is reached, before any actual data in that
   block is decoded.  This allows the caller to determine the length of the
   deflate block header for later use in random access within a deflate block.
   256 is added to the value of strm->data_type when inflate() returns
   immediately after reaching the end of the deflate block header.
 
     inflate() should normally be called until it returns STREAM_END or an
   error.  However if all decompression is to be performed in a single step (a
   single call of inflate), the parameter flush should be set to FINISH.  In
   this case all pending input is processed and all pending output is flushed;
   avail_out must be large enough to hold all of the uncompressed data for the
   operation to complete.  (The size of the uncompressed data may have been
   saved by the compressor for this purpose.) The use of FINISH is not
   required to perform an inflation in one step.  However it may be used to
   inform inflate that a faster approach can be used for the single inflate()
   call.  FINISH also informs inflate to not maintain a sliding window if the
   stream completes, which reduces inflate's memory footprint.  If the stream
   does not complete, either because not all of the stream is provided or not
   enough output space is provided, then a sliding window will be allocated and
   inflate() can be called again to continue the operation as if NO_FLUSH had
   been used.
 
      In this implementation, inflate() always flushes as much output as
   possible to the output buffer, and always uses the faster approach on the
   first call.  So the effects of the flush parameter in this implementation are
   on the return value of inflate() as noted below, when inflate() returns early
   when BLOCK or TREES is used, and when inflate() avoids the allocation of
   memory for a sliding window when FINISH is used.
 
      If a preset dictionary is needed after this call (see inflateSetDictionary
   below), inflate sets strm->adler to the Adler-32 checksum of the dictionary
   chosen by the compressor and returns NEED_DICT; otherwise it sets
   strm->adler to the Adler-32 checksum of all output produced so far (that is,
   total_out bytes) and returns OK, STREAM_END or an error code as described
   below.  At the end of the stream, inflate() checks that its computed adler32
   checksum is equal to that saved by the compressor and returns STREAM_END
   only if the checksum is correct.
 
     inflate() can decompress and check either zlib-wrapped or gzip-wrapped
   deflate data.  The header type is detected automatically, if requested when
   initializing with inflateInit2().  Any information contained in the gzip
   header is not retained, so applications that need that information should
   instead use raw inflate, see inflateInit2() below, or inflateBack() and
   perform their own processing of the gzip header and trailer.  When processing
   gzip-wrapped deflate data, strm->adler32 is set to the CRC-32 of the output
   producted so far.  The CRC-32 is checked against the gzip trailer.
 
     inflate() returns OK if some progress has been made (more input processed
   or more output produced), STREAM_END if the end of the compressed data has
   been reached and all uncompressed output has been produced, NEED_DICT if a
   preset dictionary is needed at this point, DATA_ERROR if the input data was
   corrupted (input stream not conforming to the zlib format or incorrect check
   value), STREAM_ERROR if the stream structure was inconsistent (for example
   next_in or next_out was NULL), MEM_ERROR if there was not enough memory,
   BUF_ERROR if no progress is possible or if there was not enough room in the
   output buffer when FINISH is used.  Note that BUF_ERROR is not fatal, and
   inflate() can be called again with more input and more output space to
   continue decompressing.  If DATA_ERROR is returned, the application may
   then call inflateSync() to look for a good compression block if a partial
   recovery of the data is desired.
*)

PROCEDURE [ccall] inflateEnd ["inflateEnd"] (VAR strm: PtrStream): Int;
(*
     All dynamically allocated data structures for this stream are freed.
   This function discards any unprocessed input and does not flush any pending
   output.

     inflateEnd returns OK if success, STREAM_ERROR if the stream state
   was inconsistent.  In the error case, msg may be set but then points to a
   static string (which must not be deallocated).
*)

(* Advanced functions *)

(*
   The following functions are needed only in some special applications.
*)

PROCEDURE [ccall] deflateInit2_ ["deflateInit2_"] (VAR strm: PtrStream; level, method, windowBits, memLevel, strategy: Int; version: PtrChar; stream_size: Int): Int;
(*
     This is another version of deflateInit with more compression options.  The
   fields next_in, zalloc, zfree and opaque must be initialized before by the
   caller.

     The method parameter is the compression method.  It must be DEFLATED in
   this version of the library.

     The windowBits parameter is the base two logarithm of the window size
   (the size of the history buffer).  It should be in the range 8..15 for this
   version of the library.  Larger values of this parameter result in better
   compression at the expense of memory usage.  The default value is 15 if
   deflateInit is used instead.

     windowBits can also be -8..-15 for raw deflate.  In this case, -windowBits
   determines the window size.  deflate() will then generate raw deflate data
   with no zlib header or trailer, and will not compute an adler32 check value.

     windowBits can also be greater than 15 for optional gzip encoding.  Add
   16 to windowBits to write a simple gzip header and trailer around the
   compressed data instead of a zlib wrapper.  The gzip header will have no
   file name, no extra data, no comment, no modification time (set to zero), no
   header crc, and the operating system will be set to 255 (unknown).  If a
   gzip stream is being written, strm->adler is a crc32 instead of an adler32.

     The memLevel parameter specifies how much memory should be allocated
   for the internal compression state.  memLevel=1 uses minimum memory but is
   slow and reduces compression ratio; memLevel=9 uses maximum memory for
   optimal speed.  The default value is 8.  See zconf.h for total memory usage
   as a function of windowBits and memLevel.

     The strategy parameter is used to tune the compression algorithm.  Use the
   value DEFAULT_STRATEGY for normal data, FILTERED for data produced by a
   filter (or predictor), HUFFMAN_ONLY to force Huffman encoding only (no
   string match), or RLE to limit match distances to one (run-length
   encoding).  Filtered data consists mostly of small values with a somewhat
   random distribution.  In this case, the compression algorithm is tuned to
   compress them better.  The effect of FILTERED is to force more Huffman
   coding and less string matching; it is somewhat intermediate between
   DEFAULT_STRATEGY and HUFFMAN_ONLY.  RLE is designed to be almost as
   fast as HUFFMAN_ONLY, but give better compression for PNG image data.  The
   strategy parameter only affects the compression ratio but not the
   correctness of the compressed output even if it is not set appropriately.
   FIXED prevents the use of dynamic Huffman codes, allowing for a simpler
   decoder for special applications.

     deflateInit2 returns OK if success, MEM_ERROR if there was not enough
   memory, STREAM_ERROR if any parameter is invalid (such as an invalid
   method), or VERSION_ERROR if the zlib library version (zlib_version) is
   incompatible with the version assumed by the caller (ZLIB_VERSION).  msg is
   set to null if there is no error message.  deflateInit2 does not perform any
   compression: this will be done by deflate().
*)
PROCEDURE [ccall] deflateSetDictionary ["deflateSetDictionary"] (VAR strm: PtrStream; dictionary: PtrChar; dictLength: UInt): Int;
(*
     Initializes the compression dictionary from the given byte sequence
   without producing any compressed output.  When using the zlib format, this
   function must be called immediately after deflateInit, deflateInit2 or
   deflateReset, and before any call of deflate.  When doing raw deflate, this
   function must be called either before any call of deflate, or immediately
   after the completion of a deflate block, i.e. after all input has been
   consumed and all output has been delivered when using any of the flush
   options BLOCK, PARTIAL_FLUSH, SYNC_FLUSH, or FULL_FLUSH.  The
   compressor and decompressor must use exactly the same dictionary (see
   inflateSetDictionary).

     The dictionary should consist of strings (byte sequences) that are likely
   to be encountered later in the data to be compressed, with the most commonly
   used strings preferably put towards the end of the dictionary.  Using a
   dictionary is most useful when the data to be compressed is short and can be
   predicted with good accuracy; the data can then be compressed better than
   with the default empty dictionary.

     Depending on the size of the compression data structures selected by
   deflateInit or deflateInit2, a part of the dictionary may in effect be
   discarded, for example if the dictionary is larger than the window size
   provided in deflateInit or deflateInit2.  Thus the strings most likely to be
   useful should be put at the end of the dictionary, not at the front.  In
   addition, the current implementation of deflate will use at most the window
   size minus 262 bytes of the provided dictionary.

     Upon return of this function, strm->adler is set to the adler32 value
   of the dictionary; the decompressor may later use this value to determine
   which dictionary has been used by the compressor.  (The adler32 value
   applies to the whole dictionary even if only a subset of the dictionary is
   actually used by the compressor.) If a raw deflate was requested, then the
   adler32 value is not computed and strm->adler is not set.

     deflateSetDictionary returns OK if success, or STREAM_ERROR if a
   parameter is invalid (e.g.  dictionary being NULL) or the stream state is
   inconsistent (for example if deflate has already been called for this stream
   or if not at a block boundary for raw deflate).  deflateSetDictionary does
   not perform any compression: this will be done by deflate().
*)
PROCEDURE [ccall] deflateCopy ["deflateCopy"] (VAR dest, source: PtrStream): Int;
(*
     Sets the destination stream as a complete copy of the source stream.

     This function can be useful when several compression strategies will be
   tried, for example when there are several ways of pre-processing the input
   data with a filter.  The streams that will be discarded should then be freed
   by calling deflateEnd.  Note that deflateCopy duplicates the internal
   compression state which can be quite large, so this strategy is slow and can
   consume lots of memory.

     deflateCopy returns OK if success, MEM_ERROR if there was not
   enough memory, STREAM_ERROR if the source stream state was inconsistent
   (such as zalloc being NULL).  msg is left unchanged in both source and
   destination.
*)
PROCEDURE [ccall] deflateReset ["deflateReset"] (VAR strm: PtrStream): Int;
(*
     This function is equivalent to deflateEnd followed by deflateInit,
   but does not free and reallocate all the internal compression state.  The
   stream will keep the same compression level and any other attributes that
   may have been set by deflateInit2.

     deflateReset returns OK if success, or STREAM_ERROR if the source
   stream state was inconsistent (such as zalloc or state being NULL).
*)
PROCEDURE [ccall] deflateParams ["deflateParams"] (VAR strm: PtrStream; level, strategy: Int): Int;
(*
     Dynamically update the compression level and compression strategy.  The
   interpretation of level and strategy is as in deflateInit2.  This can be
   used to switch between compression and straight copy of the input data, or
   to switch to a different kind of input data requiring a different strategy.
   If the compression level is changed, the input available so far is
   compressed with the old level (and may be flushed); the new level will take
   effect only at the next call of deflate().

     Before the call of deflateParams, the stream state must be set as for
   a call of deflate(), since the currently available input may have to be
   compressed and flushed.  In particular, strm->avail_out must be non-zero.

     deflateParams returns OK if success, STREAM_ERROR if the source
   stream state was inconsistent or if a parameter was invalid, BUF_ERROR if
   strm->avail_out was zero.
*)
PROCEDURE [ccall] deflateTune ["deflateTune"] (VAR strm: PtrStream; good_length, max_lazy, nice_length, max_chain: Int): Int;
(*
     Fine tune deflate's internal compression parameters.  This should only be
   used by someone who understands the algorithm used by zlib's deflate for
   searching for the best matching string, and even then only by the most
   fanatic optimizer trying to squeeze out the last compressed bit for their
   specific input data.  Read the deflate.c source code for the meaning of the
   max_lazy, good_length, nice_length, and max_chain parameters.

     deflateTune() can be called after deflateInit() or deflateInit2(), and
   returns OK on success, or STREAM_ERROR for an invalid deflate stream.
*)
PROCEDURE [ccall] deflateBound ["deflateBound"] (VAR strm: Stream; sourceLen: ULong): ULong;
(*
     deflateBound() returns an upper bound on the compressed size after
   deflation of sourceLen bytes.  It must be called after deflateInit() or
   deflateInit2(), and after deflateSetHeader(), if used.  This would be used
   to allocate an output buffer for deflation in a single pass, and so would be
   called before deflate().  If that first deflate() call is provided the
   sourceLen input bytes, an output buffer allocated to the size returned by
   deflateBound(), and the flush value FINISH, then deflate() is guaranteed
   to return STREAM_END.  Note that it is possible for the compressed size to
   be larger than the value returned by deflateBound() if flush options other
   than FINISH or NO_FLUSH are used.
*)
PROCEDURE [ccall] deflatePending ["deflatePending"] (VAR strm: PtrStream; VAR pending: UInt; VAR bits: Int): Int;
(*
     deflatePending() returns the number of bytes and bits of output that have
   been generated, but not yet provided in the available output.  The bytes not
   provided would be due to the available output space having being consumed.
   The number of bits of output not provided are between 0 and 7, where they
   await more bits to join them in order to fill out a full byte.  If pending
   or bits are NULL, then those values are not set.

     deflatePending returns OK if success, or STREAM_ERROR if the source
   stream state was inconsistent.
 *)
PROCEDURE [ccall] deflatePrime ["deflatePrime"] (VAR strm: PtrStream; bits, value: Int): Int;
(*
     deflatePrime() inserts bits in the deflate output stream.  The intent
   is that this function is used to start off the deflate output with the bits
   leftover from a previous deflate stream when appending to it.  As such, this
   function can only be used for raw deflate, and must be used before the first
   deflate() call after a deflateInit2() or deflateReset().  bits must be less
   than or equal to 16, and that many of the least significant bits of value
   will be inserted in the output.

     deflatePrime returns OK if success, BUF_ERROR if there was not enough
   room in the internal buffer to insert the bits, or STREAM_ERROR if the
   source stream state was inconsistent.
*)
PROCEDURE [ccall] deflateSetHeader ["deflateSetHeader"] (VAR strm: PtrStream; VAR head: gz_header): Int;
(*
     deflateSetHeader() provides gzip header information for when a gzip
   stream is requested by deflateInit2().  deflateSetHeader() may be called
   after deflateInit2() or deflateReset() and before the first call of
   deflate().  The text, time, os, extra field, name, and comment information
   in the provided gz_header structure are written to the gzip header (xflag is
   ignored -- the extra flags are set according to the compression level).  The
   caller must assure that, if not NULL, name and comment are terminated with
   a zero byte, and that if extra is not NULL, that extra_len bytes are
   available there.  If hcrc is true, a gzip header crc is included.  Note that
   the current versions of the command-line version of gzip (up through version
   1.3.x) do not support header crc's, and will report that it is a "multi-part
   gzip file" and give up.

     If deflateSetHeader is not used, the default gzip header has text false,
   the time set to zero, and os set to 255, with no extra, name, or comment
   fields.  The gzip header is returned to the default state by deflateReset().

     deflateSetHeader returns OK if success, or STREAM_ERROR if the source
   stream state was inconsistent.
*)
PROCEDURE [ccall] inflateInit2_ ["inflateInit2_"] (VAR strm: PtrStream; windowBits: Int; version: PtrChar; stream_size: Int): Int;
(*
     This is another version of inflateInit with an extra parameter.  The
   fields next_in, avail_in, zalloc, zfree and opaque must be initialized
   before by the caller.

     The windowBits parameter is the base two logarithm of the maximum window
   size (the size of the history buffer).  It should be in the range 8..15 for
   this version of the library.  The default value is 15 if inflateInit is used
   instead.  windowBits must be greater than or equal to the windowBits value
   provided to deflateInit2() while compressing, or it must be equal to 15 if
   deflateInit2() was not used.  If a compressed stream with a larger window
   size is given as input, inflate() will return with the error code
   DATA_ERROR instead of trying to allocate a larger window.

     windowBits can also be zero to request that inflate use the window size in
   the zlib header of the compressed stream.

     windowBits can also be -8..-15 for raw inflate.  In this case, -windowBits
   determines the window size.  inflate() will then process raw deflate data,
   not looking for a zlib or gzip header, not generating a check value, and not
   looking for any check values for comparison at the end of the stream.  This
   is for use with other formats that use the deflate compressed data format
   such as zip.  Those formats provide their own check values.  If a custom
   format is developed using the raw deflate format for compressed data, it is
   recommended that a check value such as an adler32 or a crc32 be applied to
   the uncompressed data as is done in the zlib, gzip, and zip formats.  For
   most applications, the zlib format should be used as is.  Note that comments
   above on the use in deflateInit2() applies to the magnitude of windowBits.

     windowBits can also be greater than 15 for optional gzip decoding.  Add
   32 to windowBits to enable zlib and gzip decoding with automatic header
   detection, or add 16 to decode only the gzip format (the zlib format will
   return a DATA_ERROR).  If a gzip stream is being decoded, strm->adler is a
   crc32 instead of an adler32.

     inflateInit2 returns OK if success, MEM_ERROR if there was not enough
   memory, VERSION_ERROR if the zlib library version is incompatible with the
   version assumed by the caller, or STREAM_ERROR if the parameters are
   invalid, such as a null pointer to the structure.  msg is set to null if
   there is no error message.  inflateInit2 does not perform any decompression
   apart from possibly reading the zlib header if present: actual decompression
   will be done by inflate().  (So next_in and avail_in may be modified, but
   next_out and avail_out are unused and unchanged.) The current implementation
   of inflateInit2() does not process any header information -- that is
   deferred until inflate() is called.
*)
PROCEDURE [ccall] inflateSetDictionary ["inflateSetDictionary"] (VAR strm: PtrStream; dictionary: PtrChar; dictLength: UInt): Int;
(*
     Initializes the decompression dictionary from the given uncompressed byte
   sequence.  This function must be called immediately after a call of inflate,
   if that call returned NEED_DICT.  The dictionary chosen by the compressor
   can be determined from the adler32 value returned by that call of inflate.
   The compressor and decompressor must use exactly the same dictionary (see
   deflateSetDictionary).  For raw inflate, this function can be called at any
   time to set the dictionary.  If the provided dictionary is smaller than the
   window and there is already data in the window, then the provided dictionary
   will amend what's there.  The application must insure that the dictionary
   that was used for compression is provided.

     inflateSetDictionary returns OK if success, STREAM_ERROR if a
   parameter is invalid (e.g.  dictionary being NULL) or the stream state is
   inconsistent, DATA_ERROR if the given dictionary doesn't match the
   expected one (incorrect adler32 value).  inflateSetDictionary does not
   perform any decompression: this will be done by subsequent calls of
   inflate().
*)
PROCEDURE [ccall] inflateGetDictionary ["inflateGetDictionary"] (VAR strm: PtrStream; VAR dictionary: PtrChar; dictLength: UInt): Int;
(*
     Returns the sliding dictionary being maintained by inflate.  dictLength is
   set to the number of bytes in the dictionary, and that many bytes are copied
   to dictionary.  dictionary must have enough space, where 32768 bytes is
   always enough.  If inflateGetDictionary() is called with dictionary equal to
   NULL, then only the dictionary length is returned, and nothing is copied.
   Similary, if dictLength is NULL, then it is not set.

     inflateGetDictionary returns OK on success, or STREAM_ERROR if the
   stream state is inconsistent.
*)
PROCEDURE [ccall] inflateSync ["inflateSync"] (VAR strm: PtrStream): Int;
(*
     Skips invalid compressed data until a possible full flush point (see above
   for the description of deflate with FULL_FLUSH) can be found, or until all
   available input is skipped.  No output is provided.

     inflateSync searches for a 00 00 FF FF pattern in the compressed data.
   All full flush points have this pattern, but not all occurrences of this
   pattern are full flush points.

     inflateSync returns OK if a possible full flush point has been found,
   BUF_ERROR if no more input was provided, DATA_ERROR if no flush point
   has been found, or STREAM_ERROR if the stream structure was inconsistent.
   In the success case, the application may save the current current value of
   total_in which indicates where valid compressed data was found.  In the
   error case, the application may repeatedly call inflateSync, providing more
   input each time, until success or end of the input data.
*)
PROCEDURE [ccall] inflateCopy ["inflateCopy"] (VAR dest, source: PtrStream): Int;
(*
     Sets the destination stream as a complete copy of the source stream.

     This function can be useful when randomly accessing a large stream.  The
   first pass through the stream can periodically record the inflate state,
   allowing restarting inflate at those points when randomly accessing the
   stream.

     inflateCopy returns OK if success, MEM_ERROR if there was not
   enough memory, STREAM_ERROR if the source stream state was inconsistent
   (such as zalloc being NULL).  msg is left unchanged in both source and
   destination.
*)
PROCEDURE [ccall] inflateReset ["inflateReset"] (VAR strm: PtrStream): Int;
(*
     This function is equivalent to inflateEnd followed by inflateInit,
   but does not free and reallocate all the internal decompression state.  The
   stream will keep attributes that may have been set by inflateInit2.

     inflateReset returns OK if success, or STREAM_ERROR if the source
   stream state was inconsistent (such as zalloc or state being NULL).
*)
PROCEDURE [ccall] inflateReset2 ["inflateReset2"] (VAR strm: PtrStream; windowBits: Int): Int;
(*
     This function is the same as inflateReset, but it also permits changing
   the wrap and window size requests.  The windowBits parameter is interpreted
   the same as it is for inflateInit2.

     inflateReset2 returns OK if success, or STREAM_ERROR if the source
   stream state was inconsistent (such as zalloc or state being NULL), or if
   the windowBits parameter is invalid.
*)
PROCEDURE [ccall] inflatePrime ["inflatePrime"] (VAR strm: PtrStream; bits, value: Int): Int;
(*
     This function inserts bits in the inflate input stream.  The intent is
   that this function is used to start inflating at a bit position in the
   middle of a byte.  The provided bits will be used before any bytes are used
   from next_in.  This function should only be used with raw inflate, and
   should be used before the first inflate() call after inflateInit2() or
   inflateReset().  bits must be less than or equal to 16, and that many of the
   least significant bits of value will be inserted in the input.

     If bits is negative, then the input stream bit buffer is emptied.  Then
   inflatePrime() can be called again to put bits in the buffer.  This is used
   to clear out bits leftover after feeding inflate a block description prior
   to feeding inflate codes.

     inflatePrime returns OK if success, or STREAM_ERROR if the source
   stream state was inconsistent.
*)
PROCEDURE [ccall] inflateMark ["inflateMark"] (VAR strm: PtrStream): Long;
(*
     This function returns two values, one in the lower 16 bits of the return
   value, and the other in the remaining upper bits, obtained by shifting the
   return value down 16 bits.  If the upper value is -1 and the lower value is
   zero, then inflate() is currently decoding information outside of a block.
   If the upper value is -1 and the lower value is non-zero, then inflate is in
   the middle of a stored block, with the lower value equaling the number of
   bytes from the input remaining to copy.  If the upper value is not -1, then
   it is the number of bits back from the current bit position in the input of
   the code (literal or length/distance pair) currently being processed.  In
   that case the lower value is the number of bytes already emitted for that
   code.

     A code is being processed if inflate is waiting for more input to complete
   decoding of the code, or if it has completed decoding but is waiting for
   more output space to write the literal or match data.

     inflateMark() is used to mark locations in the input data for random
   access, which may be at bit positions, and to note those cases where the
   output of a code may span boundaries of random access blocks.  The current
   location in the input stream can be determined from avail_in and data_type
   as noted in the description for the BLOCK flush parameter for inflate.

     inflateMark returns the value noted above or -1 << 16 if the provided
   source stream state was inconsistent.
*)
PROCEDURE [ccall] inflateGetHeader ["inflateGetHeader"] (VAR strm: PtrStream; VAR head: gz_header): Int;
(*
     inflateGetHeader() requests that gzip header information be stored in the
   provided gz_header structure.  inflateGetHeader() may be called after
   inflateInit2() or inflateReset(), and before the first call of inflate().
   As inflate() processes the gzip stream, head->done is zero until the header
   is completed, at which time head->done is set to one.  If a zlib stream is
   being decoded, then head->done is set to -1 to indicate that there will be
   no gzip header information forthcoming.  Note that BLOCK or TREES can be
   used to force inflate() to return immediately after header processing is
   complete and before any actual data is decompressed.

     The text, time, xflags, and os fields are filled in with the gzip header
   contents.  hcrc is set to true if there is a header CRC.  (The header CRC
   was valid if done is set to one.) If extra is not NULL, then extra_max
   contains the maximum number of bytes to write to extra.  Once done is true,
   extra_len contains the actual extra field length, and extra contains the
   extra field, or that field truncated if extra_max is less than extra_len.
   If name is not NULL, then up to name_max characters are written there,
   terminated with a zero unless the length is greater than name_max.  If
   comment is not NULL, then up to comm_max characters are written there,
   terminated with a zero unless the length is greater than comm_max.  When any
   of extra, name, or comment are not NULL and the respective field is not
   present in the header, then that field is set to NULL to signal its
   absence.  This allows the use of deflateSetHeader() with the returned
   structure to duplicate the header.  However if those fields are set to
   allocated memory, then the application will need to save those pointers
   elsewhere so that they can be eventually freed.

     If inflateGetHeader is not used, then the header information is simply
   discarded.  The header is always checked for validity, including the header
   CRC if present.  inflateReset() will reset the process to discard the header
   information.  The application would need to call inflateGetHeader() again to
   retrieve the header from the next gzip stream.

     inflateGetHeader returns OK if success, or STREAM_ERROR if the source
   stream state was inconsistent.
*)
PROCEDURE [ccall] inflateBackInit_ ["inflateBackInit_"] (VAR strm: PtrStream; windowBits: Int; window: Pointer; version: PtrChar; stream_size: Int): Int;
(*
     Initialize the internal stream state for decompression using inflateBack()
   calls.  The fields zalloc, zfree and opaque in strm must be initialized
   before the call.  If zalloc and zfree are NULL, then the default library-
   derived memory allocation routines are used.  windowBits is the base two
   logarithm of the window size, in the range 8..15.  window is a caller
   supplied buffer of that size.  Except for special applications where it is
   assured that deflate was used with small window sizes, windowBits must be 15
   and a 32K byte window must be supplied to be able to decompress general
   deflate streams.

     See inflateBack() for the usage of these routines.

     inflateBackInit will return OK on success, STREAM_ERROR if any of
   the parameters are invalid, MEM_ERROR if the internal state could not be
   allocated, or VERSION_ERROR if the version of the library does not match
   the version of the header file.
*)
PROCEDURE [ccall] inflateBack ["inflateBack"] (VAR strm: PtrStream; inf: InFunc; in_desc: PtrVoid; outf: OutFunc; out_desc: PtrVoid): Int;
(*
     inflateBack() does a raw inflate with a single call using a call-back
   interface for input and output.  This is potentially more efficient than
   inflate() for file i/o applications, in that it avoids copying between the
   output and the sliding window by simply making the window itself the output
   buffer.  inflate() can be faster on modern CPUs when used with large
   buffers.  inflateBack() trusts the application to not change the output
   buffer passed by the output function, at least until inflateBack() returns.

     inflateBackInit() must be called first to allocate the internal state
   and to initialize the state with the user-provided window buffer.
   inflateBack() may then be used multiple times to inflate a complete, raw
   deflate stream with each call.  inflateBackEnd() is then called to free the
   allocated state.

     A raw deflate stream is one with no zlib or gzip header or trailer.
   This routine would normally be used in a utility that reads zip or gzip
   files and writes out uncompressed files.  The utility would decode the
   header and process the trailer on its own, hence this routine expects only
   the raw deflate stream to decompress.  This is different from the normal
   behavior of inflate(), which expects either a zlib or gzip header and
   trailer around the deflate stream.

     inflateBack() uses two subroutines supplied by the caller that are then
   called by inflateBack() for input and output.  inflateBack() calls those
   routines until it reads a complete deflate stream and writes out all of the
   uncompressed data, or until it encounters an error.  The function's
   parameters and return types are defined above in the in_func and out_func
   typedefs.  inflateBack() will call in(in_desc, &buf) which should return the
   number of bytes of provided input, and a pointer to that input in buf.  If
   there is no input available, in() must return zero--buf is ignored in that
   case--and inflateBack() will return a buffer error.  inflateBack() will call
   out(out_desc, buf, len) to write the uncompressed data buf[0..len-1].  out()
   should return zero on success, or non-zero on failure.  If out() returns
   non-zero, inflateBack() will return with an error.  Neither in() nor out()
   are permitted to change the contents of the window provided to
   inflateBackInit(), which is also the buffer that out() uses to write from.
   The length written by out() will be at most the window size.  Any non-zero
   amount of input may be provided by in().

     For convenience, inflateBack() can be provided input on the first call by
   setting strm->next_in and strm->avail_in.  If that input is exhausted, then
   in() will be called.  Therefore strm->next_in must be initialized before
   calling inflateBack().  If strm->next_in is NULL, then in() will be called
   immediately for input.  If strm->next_in is not NULL, then strm->avail_in
   must also be initialized, and then if strm->avail_in is not zero, input will
   initially be taken from strm->next_in[0 ..  strm->avail_in - 1].

     The in_desc and out_desc parameters of inflateBack() is passed as the
   first parameter of in() and out() respectively when they are called.  These
   descriptors can be optionally used to pass any information that the caller-
   supplied in() and out() functions need to do their job.

     On return, inflateBack() will set strm->next_in and strm->avail_in to
   pass back any unused input that was provided by the last in() call.  The
   return values of inflateBack() can be STREAM_END on success, BUF_ERROR
   if in() or out() returned an error, DATA_ERROR if there was a format error
   in the deflate stream (in which case strm->msg is set to indicate the nature
   of the error), or STREAM_ERROR if the stream was not properly initialized.
   In the case of BUF_ERROR, an input or output error can be distinguished
   using strm->next_in which will be NULL only if in() returned an error.  If
   strm->next_in is not NULL, then the BUF_ERROR was due to out() returning
   non-zero.  (in() will always be called before out(), so strm->next_in is
   assured to be defined if out() returns non-zero.) Note that inflateBack()
   cannot return OK.
*)
PROCEDURE [ccall] inflateBackEnd ["inflateBackEnd"] (VAR strm: PtrStream): Int;
(*
     All memory allocated by inflateBackInit() is freed.

     inflateBackEnd() returns OK on success, or STREAM_ERROR if the stream
   state was inconsistent.
*)
PROCEDURE [ccall] zlibCompileFlags ["zlibCompileFlags"] (): ULong;
(* Return flags indicating compile-time options.

    Type sizes, two bits each, 00 = 16 bits, 01 = 32, 10 = 64, 11 = other:
     1.0: size of uInt
     3.2: size of uLong
     5.4: size of voidpf (pointer)
     7.6: size of z_Offset

    Compiler, assembler, and debug options:
     8: DEBUG
     9: ASMV or ASMINF -- use ASM code
     10: ZLIB_WINAPI -- exported functions use the WINAPI calling convention
     11: 0 (reserved)

    One-time table building (smaller code, but not thread-safe if true):
     12: BUILDFIXED -- build static block decoding tables when needed
     13: DYNAMIC_CRC_TABLE -- build CRC calculation tables when needed
     14,15: 0 (reserved)

    Library content (indicates missing functionality):
     16: NO_GZCOMPRESS -- gz* functions cannot compress (to avoid linking
                          deflate code when not needed)
     17: NO_GZIP -- deflate can't write gzip streams, and inflate can't detect
                    and decode gzip streams (to avoid linking crc code)
     18-19: 0 (reserved)

    Operation variations (changes in library functionality):
     20: PKZIP_BUG_WORKAROUND -- slightly more permissive inflate
     21: FASTEST -- deflate algorithm with only one, lowest compression level
     22,23: 0 (reserved)

    The sprintf variant used by gzprintf (zero is best):
     24: 0 = vs*, 1 = s* -- 1 means limited to 20 arguments after the format
     25: 0 = *nprintf, 1 = *printf -- 1 means gzprintf() not secure!
     26: 0 = returns value, 1 = void -- 1 means inferred string length returned

    Remainder:
     27-31: 0 (reserved)
*)

(* utility functions *)

(*
     The following utility functions are implemented on top of the basic
   stream-oriented functions.  To simplify the interface, some default options
   are assumed (compression level and memory usage, standard memory allocation
   functions).  The source code of these utility functions can be modified if
   you need special options.
*)

PROCEDURE [ccall] compress ["compress"] (dest: PtrChar; VAR destLen: ULong; source: PtrChar; sourceLen: ULong): Int;
(*
     Compresses the source buffer into the destination buffer.  sourceLen is
   the byte length of the source buffer.  Upon entry, destLen is the total size
   of the destination buffer, which must be at least the value returned by
   compressBound(sourceLen).  Upon exit, destLen is the actual size of the
   compressed buffer.

     compress returns OK if success, MEM_ERROR if there was not
   enough memory, BUF_ERROR if there was not enough room in the output
   buffer.
*)

PROCEDURE [ccall] compress2 ["compress2"] (dest: PtrChar; VAR destLen: ULong; source: PtrChar; sourceLen: ULong; level: Int): Int;
(*
     Compresses the source buffer into the destination buffer.  The level
   parameter has the same meaning as in deflateInit.  sourceLen is the byte
   length of the source buffer.  Upon entry, destLen is the total size of the
   destination buffer, which must be at least the value returned by
   compressBound(sourceLen).  Upon exit, destLen is the actual size of the
   compressed buffer.

     compress2 returns OK if success, MEM_ERROR if there was not enough
   memory, BUF_ERROR if there was not enough room in the output buffer,
   STREAM_ERROR if the level parameter is invalid.
*)

PROCEDURE [ccall] compressBound ["compressBound"] (sourceLen: ULong): ULong;
(*
     compressBound() returns an upper bound on the compressed size after
   compress() or compress2() on sourceLen bytes.  It would be used before a
   compress() or compress2() call to allocate the destination buffer.
*)

PROCEDURE [ccall] uncompress ["uncompress"] (dest: PtrChar; VAR destLen: ULong; source: PtrChar; sourceLen: ULong): Int;
(*
     Decompresses the source buffer into the destination buffer.  sourceLen is
   the byte length of the source buffer.  Upon entry, destLen is the total size
   of the destination buffer, which must be large enough to hold the entire
   uncompressed data.  (The size of the uncompressed data must have been saved
   previously by the compressor and transmitted to the decompressor by some
   mechanism outside the scope of this compression library.) Upon exit, destLen
   is the actual size of the uncompressed buffer.

     uncompress returns OK if success, MEM_ERROR if there was not
   enough memory, BUF_ERROR if there was not enough room in the output
   buffer, or DATA_ERROR if the input data was corrupted or incomplete.  In
   the case where there is not enough room, uncompress() will fill the output
   buffer with the uncompressed data up to that point.
*)


(* checksum functions *)

(*
     These functions are not related to compression but are exported
   anyway because they might be useful in applications using the compression
   library.
*)

PROCEDURE [ccall] adler32 ["adler32"] (adler: ULong; buf: PtrChar; len: UInt): ULong;
(*
     Update a running Adler-32 checksum with the bytes buf[0..len-1] and
   return the updated checksum.  If buf is NULL, this function returns the
   required initial value for the checksum.

     An Adler-32 checksum is almost as reliable as a CRC32 but can be computed
   much faster.

   Usage example:

     uLong adler = adler32(0L, NULL, 0);

     while (read_buffer(buffer, length) != EOF) {
       adler = adler32(adler, buffer, length);
     }
     if (adler != original_adler) error();
*)

PROCEDURE [ccall] adler32_combine ["adler32_combine"] (adler1, adler2: ULong; len2: Offset): ULong;
(*
     Combine two Adler-32 checksums into one.  For two sequences of bytes, seq1
   and seq2 with lengths len1 and len2, Adler-32 checksums were calculated for
   each, adler1 and adler2.  adler32_combine() returns the Adler-32 checksum of
   seq1 and seq2 concatenated, requiring only adler1, adler2, and len2.  Note
   that the z_off_t type (like off_t) is a signed integer.  If len2 is
   negative, the result has no meaning or utility.
*)

PROCEDURE [ccall] crc32 ["crc32"] (crc: ULong; buf: PtrChar; len: UInt): ULong;
(*
     Update a running CRC-32 with the bytes buf[0..len-1] and return the
   updated CRC-32.  If buf is NULL, this function returns the required
   initial value for the crc.  Pre- and post-conditioning (one's complement) is
   performed within this function so it shouldn't be done by the application.

   Usage example:

     uLong crc = crc32(0L, NULL, 0);

     while (read_buffer(buffer, length) != EOF) {
       crc = crc32(crc, buffer, length);
     }
     if (crc != original_crc) error();
*)

PROCEDURE [ccall] crc32_combine ["crc32_combine"] (crc1, crc2: ULong; len2: Offset): ULong;
(*
     Combine two CRC-32 check values into one.  For two sequences of bytes,
   seq1 and seq2 with lengths len1 and len2, CRC-32 check values were
   calculated for each, crc1 and crc2.  crc32_combine() returns the CRC-32
   check value of seq1 and seq2 concatenated, requiring only crc1, crc2, and
   len2.
*)

(* undocumented functions *)

PROCEDURE [ccall] zError   ["zError"  ] (err: Int): PtrChar;
PROCEDURE [ccall] get_crc_table    ["get_crc_table"   ] (): PtrVoid;
PROCEDURE [ccall] inflateSyncPoint ["inflateSyncPoint"] (VAR z: PtrStream): Int;
PROCEDURE [ccall] inflateUndermine ["inflateUndermine"] (VAR z: PtrStream; x: Int): Int;
PROCEDURE [ccall] inflateResetKeep ["inflateResetKeep"] (VAR z: PtrStream): Int;
PROCEDURE [ccall] deflateResetKeep ["deflateResetKeep"] (VAR z: PtrStream): Int;
(*
   PROCEDURE [ccall] gzprintf ["gzprintf"] (file: gzFile; format: PtrChar; args: ...): Int;
*)

END ZlibLib.