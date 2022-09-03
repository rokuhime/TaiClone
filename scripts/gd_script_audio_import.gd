class_name AudioLoader

# GDScriptAudioImport v0.1

# MIT License
#
# Copyright (c) 2020 Gianclgar (Giannino Clemente) gianclgar@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


static func load_file(file_path: String) -> AudioStream:
	var stream := AudioStreamSample.new()

	var file := File.new()
	if file.open(file_path, File.READ):
		push_warning("Error with file: %s." % file_path)
		file.close()
		return stream

	var bytes := file.get_buffer(file.get_len())
	file.close()

	if file_path.ends_with(".wav"):
		# ---------- REFERENCE ---------------
		# note: typical values doesn't always match

		# Positions  Typical Value  Description
		#  1 -  4    "RIFF"         Marks the file as a RIFF multimedia file. Characters are each 1 byte long.
		#  5 -  8    (integer)      The overall file size in bytes (32-bit integer) minus 8 bytes. Typically, you'd fill this in after file creation is complete.
		#  9 - 12    "WAVE"         RIFF file format header. For our purposes, it always equals "WAVE".
		# 13 - 16    "fmt "         Format sub-chunk marker. Includes trailing null.
		# 17 - 20    16             Length of the rest of the format sub-chunk below.
		# 21 - 22    1              Audio format code, a 2 byte (16 bit) integer. 1 = PCM (pulse code modulation).
		# 23 - 24    2              Number of channels as a 2 byte (16 bit) integer. 1 = mono, 2 = stereo, etc.
		# 25 - 28    44100          Sample rate as a 4 byte (32 bit) integer. Common values are 44100 (CD), 48000 (DAT). Sample rate = number of samples per second, or Hertz.
		# 29 - 32    176400         (SampleRate * BitsPerSample * Channels) / 8 This is the Byte rate.
		# 33 - 34    4              (BitsPerSample * Channels) / 8 1 = 8 bit mono, 2 = 8 bit stereo or 16 bit mono, 4 = 16 bit stereo.
		# 35 - 36    16             Bits per sample.
		# 37 - 40    "data"         Data sub-chunk header. Marks the beginning of the raw data section.
		# 41 - 44    (integer)      The number of bytes of the data section below this point. Also equal to (#ofSamples * #ofChannels * BitsPerSample) / 8
		# 45+                       The raw audio data.

		var buffer := StreamPeerBuffer.new()
		var i := 0
		while i < 100:
			var those4bytes := bytes.subarray(i, i + 3).get_string_from_utf8()
			match those4bytes:
				"RIFF":
					i = _print_ok(those4bytes, i) + 4
				"WAVE":
					i = _print_ok(those4bytes, i)
				"fmt ":
					i = _print_ok(those4bytes, i)

					buffer.data_array = bytes.subarray(i, i + 3)
					print_debug("Format subchunk size: %s." % buffer.get_32())

					buffer.data_array = bytes.subarray(i + 4, i + 5)
					var format_code := buffer.get_16()
					var format_name := ""
					match format_code:
						0:
							format_name = "8_BITS"
						1:
							format_name = "16_BITS"
						2:
							format_name = "IMA_ADPCM"
					print_debug("Format: %s %s." % [format_code, format_name])
					stream.format = format_code

					buffer.data_array = bytes.subarray(i + 6, i + 7)
					var channel_num := buffer.get_16()
					print_debug("Number of channels: %s." % channel_num)
					stream.stereo = channel_num == 2

					buffer.data_array = bytes.subarray(i + 8, i + 11)
					var sample_rate := buffer.get_32()
					print_debug("Sample Rate: %s." % sample_rate)
					stream.mix_rate = sample_rate

					buffer.data_array = bytes.subarray(i + 12, i + 15)
					print_debug("Byte rate: %s." % buffer.get_32())

					buffer.data_array = bytes.subarray(i + 16, i + 17)
					print_debug("BitsPerSample * Channel / 8: %s." % buffer.get_16())

					buffer.data_array = bytes.subarray(i + 18, i + 19)
					print_debug("Bits per sample: %s." % buffer.get_16())

					i += 20
				"data":
					buffer.data_array = bytes.subarray(i + 4, i + 7)
					var audio_data_size := buffer.get_32()
					print_debug("Audio data/stream size is %s bytes." % audio_data_size)

					var data_entry_point := i + 8
					print_debug("Audio data starts at byte: %s." % data_entry_point)

					stream.data = bytes.subarray(data_entry_point, data_entry_point + audio_data_size - 1)
					break
				_:
					i += 1

	elif file_path.ends_with(".ogg"):
		var new_stream := AudioStreamOGGVorbis.new()
		new_stream.data = bytes
		return new_stream

	elif file_path.ends_with(".mp3"):
		var new_stream := AudioStreamMP3.new()
		new_stream.data = bytes
		return new_stream

	else:
		push_warning("Wrong filetype or format: %s." % file_path)

	return stream


static func _print_ok(those4bytes: String, i: int) -> int:
	print_debug("%s OK at bytes %s-%s" % [those4bytes, i, i + 3])
	return i + 4
