local bypassUI = true

function GTetris.GetFixedValue(input)
    local target = 0.016666
    return input / (target / RealFrameTime())
end

function GTetris.GetFixedMovingSpeed(input)
    local target = 1
    return input / (target / RealFrameTime())
end

function GTetris.IncFV(input, add, mins, maxs)
    return math.Clamp(input + GTetris.GetFixedValue(add), mins, maxs)
end


function GTetris.ConsoleCommand(cmd)
    LocalPlayer():ConCommand(cmd)
end