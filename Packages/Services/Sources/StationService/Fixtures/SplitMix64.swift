// Geçici (K-23): fixture üretimi için. Yalnızca Debug derlemesinde var.
#if DEBUG
/// Sabit tohumlu, platformdan bağımsız sözde rastgele üreteç (SplitMix64). `SystemRandomNumberGenerator`
/// tohum almadığı için kullanılmaz.
struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    /// Dizgeden türetilen tohumla (FNV-1a). `String.hashValue` her açılışta değiştiği için kullanılmaz.
    init(seeding text: String) {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in text.utf8 {
            hash = (hash ^ UInt64(byte)) &* 0x0000_0100_0000_01B3
        }
        state = hash
    }

    /// `0..<upperBound` aralığında değer.
    mutating func next(below upperBound: Int) -> Int {
        Int(next() % UInt64(upperBound))
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }

    /// Aralıkta düzgün dağılmış değer.
    mutating func unit(in range: ClosedRange<Double>) -> Double {
        let fraction = Double(next() >> 11) / Double(UInt64(1) << 53)
        return range.lowerBound + fraction * (range.upperBound - range.lowerBound)
    }
}
#endif
