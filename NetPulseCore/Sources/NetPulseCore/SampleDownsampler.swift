import Foundation

/// Reduces a throughput series to at most `maxPoints` points for charting.
///
/// A chart a few hundred points wide can't show more detail than that, but
/// rendering the raw series meant up to 3600 samples × 3 marks re-laid-out
/// every second. Each bucket keeps its *peak* download and upload values
/// rather than the mean, so short bursts stay visible instead of being
/// smoothed away — for a speed graph the spikes are the interesting part.
public enum SampleDownsampler {
    public static func downsample(_ samples: [NetworkSample], maxPoints: Int) -> [NetworkSample] {
        guard maxPoints > 0, samples.count > maxPoints else { return samples }

        let bucketSize = Int((Double(samples.count) / Double(maxPoints)).rounded(.up))
        var result: [NetworkSample] = []
        result.reserveCapacity(maxPoints)

        var start = 0
        while start < samples.count {
            let end = min(start + bucketSize, samples.count)
            let bucket = samples[start..<end]
            // Reuse the last sample's id and timestamp so a bucket keeps a
            // stable identity between renders instead of being treated as a
            // brand new point every second.
            let last = bucket[bucket.index(before: bucket.endIndex)]
            result.append(NetworkSample(
                id: last.id,
                timestamp: last.timestamp,
                downloadBytesPerSecond: bucket.map(\.downloadBytesPerSecond).max() ?? 0,
                uploadBytesPerSecond: bucket.map(\.uploadBytesPerSecond).max() ?? 0
            ))
            start = end
        }
        return result
    }
}
