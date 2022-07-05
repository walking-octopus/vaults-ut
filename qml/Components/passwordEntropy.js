const calcEntropy = (charset, length) =>
  Math.round(length * Math.log(charset) / Math.LN2)

const stdCharsets = [{
  name: 'lowercase',
  re: /[a-z]/,
  length: 26
}, {
  name: 'uppercase',
  re: /[A-Z]/,
  length: 26
}, {
  name: 'numbers',
  re: /[0-9]/,
  length: 10
}, {
  name: 'symbols',
  re: /[^a-zA-Z0-9]/,
  length: 33
}]

const calcCharsetLengthWith = charsets =>
  string =>
    charsets.reduce((length, charset) =>
      length + (charset.re.test(string) ? charset.length : 0), 0)

const calcCharsetLength = calcCharsetLengthWith(stdCharsets)

const passwordEntropy = string =>
  string ? calcEntropy(calcCharsetLength(string), string.length) : 0