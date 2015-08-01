class Environment {
    let outer: Environment?
    var vars: [String : Expression] = [:]
    init(outer: Environment?) { self.outer = outer }
    func add(symbol: Symbol, expression: Expression) { vars[symbol.name] = expression }
    func lookup(symbol: Symbol)
        -> Expression! { return vars[symbol.name] is Expression ? vars[symbol.name] : outer?.lookup(symbol) }
}
class Evaluator {
    var rootEnv = Environment(outer: nil)
    func tokenize(input: String) -> [String] {
        var tokens: [String] = []
        var nextIndex = input.startIndex
        while nextIndex != input.endIndex {
            let read = readNextToken(input, startIndex: nextIndex)
            tokens += read.token!
            nextIndex = read.nextIndex
        }
        return tokens
    }
    func getNextChar(input: String, nextIndex: String.Index)
        -> String { return input.substringWithRange(nextIndex..<advance(nextIndex, 1)) }
    func readNextToken(input :String, startIndex : String.Index) -> (token : String?, nextIndex : String.Index) {
        var nextIndex = startIndex
        while nextIndex != input.endIndex {
            if input.substringFromIndex(nextIndex).hasPrefix(" ") {
                nextIndex++
            } else {
                break
            }
        }
        if nextIndex == input.endIndex { return (nil, nextIndex) }
        let nextChar = getNextChar(input, nextIndex: nextIndex)
        switch nextChar {
        case "(", ")", "+", "*", "-", "/", "%", "<", ">", "=", "\\": return (nextChar, ++nextIndex)
        case "1", "2", "3", "4", "5", "6", "7", "8", "9", "0": return readNumber(input, startIndex: nextIndex)
        default: return readSymbol(input, startIndex: nextIndex)
        }
    }
    func readNumber(input: String, startIndex: String.Index) -> (token: String?, nextIndex:String.Index) {
        var value = ""
        var nextIndex = startIndex
        while nextIndex != input.endIndex {
            let nextChar = getNextChar(input, nextIndex: nextIndex)
            switch nextChar {
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9": value += nextChar
            default: return (value, nextIndex)
            }
            nextIndex++
        }
        return (value, nextIndex)
    }
    func readSymbol(input: String, startIndex: String.Index) -> (token: String?, nextIndex: String.Index) {
        var token = ""
        var nextIndex = startIndex
        while nextIndex != input.endIndex {
            let nextChar = getNextChar(input, nextIndex: nextIndex)
            switch nextChar {
            case " ", ")": return (token, nextIndex)
            default : token += nextChar
            }
            nextIndex++
        }
        return (token, nextIndex)
    }
    func parse(input: String) -> Expression? {
        let tokens = tokenize(input)
        return parseTokens(tokens, startIndex: tokens.startIndex, endIndex: tokens.endIndex).expression
    }
    func parseTokens(tokens: [String], startIndex: Int, endIndex: Int) -> (expression: Expression, lastIndex: Int) {
        switch tokens[startIndex] {
        case "(": return readTillListEnd(tokens, startIndex: startIndex + 1, endIndex: endIndex)
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9": return (Number(value: tokens[startIndex].toInt()!), startIndex)
        case "+", "*", "-", "/", "%", "<", ">", "=", "\\": return (Symbol(name: tokens[startIndex]), startIndex)
        default: return (Symbol(name: tokens[startIndex]), startIndex)
        }
    }
    func readTillListEnd(tokens: [String], startIndex: Int, endIndex: Int) -> (expression: Expression, lastIndex: Int) {
        var elements: [Expression] = []
        var nextIndex = startIndex
        while nextIndex < endIndex && tokens[nextIndex] != ")" {
            let parsed = parseTokens(tokens, startIndex: nextIndex, endIndex: endIndex)
            elements += parsed.expression
            nextIndex = parsed.lastIndex + 1
        }
        return (List(es: elements), nextIndex)
    }
    func eval(expression: Expression) -> Expression { return evalr(expression, env: rootEnv) }
    func nv /* number value */ (v: Expression) -> Int { return (v as Number).value }
    func nvs /* number values */ (es: [Expression], env: Environment)
        -> [Int] { return map(es[1..<countElements(es)]){ self.nv(self.evalr($0, env: env)) } }
    func narithmetic(ns: [Int], op: (Int, Int) -> Int)
        -> Number { return Number(value: reduce(ns[1..<countElements(ns)], ns[0], op)) }
    func ncompare(ns: [Int], op: (Int, Int) -> Bool)
        -> Boolean { return Boolean(value: op(ns[0], ns[1])) }
    func bindParam(params: List, args: [Expression], outer: Environment) -> Environment {
        var env = Environment(outer: outer)
        for (idx, param) in enumerate(params.es) {
            env.add(param as Symbol, expression: evalr(args[idx], env: env))
        }
        return env
    }
    func evalr(expression: Expression, env: Environment) -> Expression {
        switch expression {
        case let x where x is Procedure: return evalr((x as Procedure).body, env:env)
        case let x where x is Symbol: return (env.lookup(x as Symbol) is Expression) ? env.lookup(x as Symbol)! : expression
        case let x where x is List:
            let l = x as List
            switch (l.es[0] as Symbol).name {
            case "+": return narithmetic(nvs(l.es, env: env)){ $0 + $1 }
            case "-": return narithmetic(nvs(l.es, env: env)){ $0 - $1 }
            case "*": return narithmetic(nvs(l.es, env: env)){ $0 * $1 }
            case "/": return narithmetic(nvs(l.es, env: env)){ $0 / $1 }
            case "%": return narithmetic(nvs(l.es, env: env)){ $0 % $1 }
            case "<": return ncompare(nvs(l.es, env: env)){ $0 < $1 }
            case ">": return ncompare(nvs(l.es, env: env)){ $0 > $1 }
            case "=": return ncompare(nvs(l.es, env: env)){ $0 == $1 }
            case "let":
                var localEnv = Environment(outer: env)
                var isName = true
                var name: Symbol? = nil
                for name_or_value in (l.es[1] as List).es {
                    if isName {
                        name = (name_or_value as Symbol)
                    } else {
                        localEnv.add(name!, expression: evalr(name_or_value, env: env))
                    }
                    isName =  !isName
                }
                return evalr(l.es[2], env: localEnv)
            case "map":
                let proc = evalr(l.es[2], env: env) as Procedure
                let targets = evalr(l.es[1] as List, env: env) as List
                return List(es: map(targets.es){ self.evalr(proc, env: self.bindParam(proc.params, args: [$0], outer: env)) })
            case "defun":
                env.add(l.es[1] as Symbol, expression: Procedure(params: l.es[2] as List, body: l.es[3] as List, lexicalEnv: env))
                return Nil()
            case "if":    return evalr(l.es[(evalr(l.es[1], env: env) as Boolean).value ? 2 : 3], env: env)
            case "\\":    return Procedure(params: l.es[1] as List, body: l.es[2] as List, lexicalEnv: env)
            case "quote": return List(es: (l.es[1] as List).es)
            case "list":  return List(es: map(l.es[1..<countElements(l.es)]){ $0 }) // map is used to cnvert Slice to Array
            case "first": return (l.es[1] as List).es[0]
            case "rest":
                var src = l.es[1] as List
                return List(es: map(src.es[1..<countElements(src.es)]){ $0 }) // map is used to cnvert Slice to Array
            case let function where env.lookup(l.es[0] as Symbol):
                let proc = env.lookup(l.es[0] as Symbol) as Procedure
                return evalr(proc, env: bindParam(proc.params, args: map(l.es[1..<countElements(l.es)]){ $0 }, outer: env))
            default: return Nil()
            }
        default: return expression
        }
    }
}