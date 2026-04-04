local Formatting = {}

function Formatting.DistanceStuds(distance)
    if distance == nil then
        return nil
    end

    return string.format("%d studs", math.floor(distance + 0.5))
end

function Formatting.Health(current, maximum)
    if current == nil or maximum == nil then
        return nil
    end

    return string.format(
        "HP: %d/%d",
        math.floor(current + 0.5),
        math.floor(maximum + 0.5)
    )
end

function Formatting.Progress(percent)
    if percent == nil then
        return nil
    end

    percent = math.clamp(math.floor(percent + 0.5), 0, 100)
    return string.format("Progress: %d%%", percent)
end

function Formatting.Status(label, value)
    return string.format("%s: %s", tostring(label), tostring(value))
end

return Formatting