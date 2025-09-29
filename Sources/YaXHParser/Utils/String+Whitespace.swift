extension String {
    func trimmingWhitespace() -> String {
        guard let start = self.firstIndex(where: { !$0.isWhitespace }),
              let end = self.lastIndex(where: { !$0.isWhitespace }) else {
            return ""
        }
        return String(self[start ... end])
    }
}
