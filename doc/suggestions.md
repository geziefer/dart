### **9. Mixed Responsibilities**
• **Issue**: Controllers handle both business logic and UI formatting
• **Recommendation**: Separate concerns - move formatting to view models or utilities

### **10. Inconsistent Stats Labels**
• **Issue**: Different abbreviations across games (♛E, ♛P, ♛Z, etc.)
• **Recommendation**: Create consistent stats labeling system

### **13. Tight Coupling**
• **Issue**: Controllers directly reference UI components (BuildContext in pressNumpadButton)
• **Recommendation**: Use events or callbacks to decouple

### **17. No Configuration Management**
• **Issue**: Game rules and settings scattered throughout code
• **Recommendation**: Centralize game configuration

### **18. Inconsistent Error States**
• **Issue**: No consistent handling of error states in UI
• **Recommendation**: Create standard error handling patterns
