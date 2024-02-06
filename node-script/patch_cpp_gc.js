const fs = require('fs');

var lines = fs.readFileSync(process.argv[2], 'utf-8');

lines = lines.replace("struct V8_EXPORT CppHeapCreateParams {", 
`struct V8_EXPORT CppHeapCreateParams {
  CppHeapCreateParams(const CppHeapCreateParams&) = delete;
  CppHeapCreateParams& operator=(const CppHeapCreateParams&) = delete;`
  );
        
fs.writeFileSync(process.argv[2], lines);