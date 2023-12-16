local r = {}


-- Funktion für Zufallszahl für Monte-Carlo Berechnungen aus https://stackoverflow.com/questions/20154991/generating-uniform-random-numbers-in-lua
local A1, A2 = 727595, 798405  -- 5^17=D20*A1+A2
local D20, D40 = 1048576, 1099511627776  -- 2^20, 2^40
local X1, X2 = 0, 1

function rand()
    local U = X2*A2
    local V = (X1*A2 + X2*A1) % D20
    V = (V*D20 + U) % D40
    X1 = math.floor(V/D20)
    X2 = V - X1*D20
    return V/D40
end


-- Funktion für Zufallszahl mit variablen Parametern
function r.jrand(...)
    local numArgs = select("#", ...) -- Anzahl der übergebenen Argumente
    local a, b, mode

    -- Je nach Anzahl der Argumente
    if numArgs == 0 then
        a, b, mode = 0, 1, 'r'
    elseif numArgs == 1 then
        a, b, mode = 0, select(1, ...), 'r'
    else
        a, b = select(1, ...), select(2, ...)
        if type(b) == 'number' then
            mode = 'r'
        elseif  b == 'd' then
            mode = b
        elseif  b == 'r' then
            mode = b
            b = 0
        elseif  b == 'h' then
            mode = 'd'
            a = a/2.0
        end
            
    
    end

    -- Überprüfe und behandle den Modus
    if mode == 'r' then
        return a + rand() * (b - a)
    elseif mode == 'd' then
        return -a + rand() * (2 * a)
    else
        return 0
    end
end

return r