module(..., package.seeall)

local appID = "4028cb962895efc50128fc99d4b7025b"
local adNetwork = "inmobi"

local filePath = system.pathForFile("scores.txt", system.DocumentsDirectory)
local numHighScores = 10

local function string_split(string, delimiter)
    local result = { }
    local from  = 1
    local delim_from, delim_to = string.find( string, delimiter, from  )
    while delim_from do
        table.insert( result, string.sub( string, from , delim_from-1 ) )
        from  = delim_to + 1
        delim_from, delim_to = string.find( string, delimiter, from  )
    end
    table.insert( result, string.sub( string, from  ) )
    return result
end

function readHighScores()
    
    local file = io.open(filePath, "r")
    local highScores = {}

    if file then
        local index = 1
        for line in io.lines(filePath) do
            local t = string_split(line, ":")
            --pos, name, score = string.split(line, ":")
            local tableScore = {}
            tableScore.pos = t[1]
            tableScore.name = t[2]
            tableScore.score = t[3]
            table.insert(highScores, tableScore)
            index = index + 1

        end
        io.close(file)
    else
        local file = io.open(filePath, "w")
        for index = 1,numHighScores do
            file:write(index, ":", "", ":", "0", "\n")
            local tableScore = {}
            tableScore.pos = index
            tableScore.name = ""
            tableScore.score = 0
            table.insert(highScores, tableScore)
        end
        io.close(file)
    end

    return highScores
end

function saveHighScores(numHighScores, highScores)
    local file = io.open(filePath, "w")

    for index = 1,numHighScores do
        file:write(index, ":", highScores[index].name, ":", highScores[index].score, "\n")
    end
    io.close(file)
end

-- Regresa el nuevo lugar en la tabla de posiciones, o 0 si no entra en la tabla
function isNewHighScore(score, highScores)

    local newPlace = 0
    local writeTable = false

    for i=1,numHighScores do
        if score >= tonumber(highScores[i].score) then
            local newScore = {}
            newScore.pos = i
            newScore.name = "Rodolfo"
            newScore.score = score
            table.insert(highScores, i, newScore)
            writeTable = true
            newPlace = i
            break
        end
    end

    if writeTable then
        saveHighScores(numHighScores, highScores)
    end

    return newPlace
end
