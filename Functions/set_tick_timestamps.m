function set_tick_timestamps(axes, use_milliseconds)

%% Find nice round numbers to use
number_of_ticks = 5;
x_lim = xlim(axes);
xrange = x_lim(2) - x_lim(1);
xrange = xrange / number_of_ticks;
nice = floor(log10(xrange));
frac = 1;
if nice > 1
    frac = 4;
end
nice = round(xrange * frac / 10^nice) / frac * 10^nice;

x_tick = floor(x_lim(1)):nice:ceil(x_lim(2));

x_tick_minutes = floor(x_tick / 60);
x_tick_seconds = mod(x_tick,60);

if use_milliseconds
        labels = compose('%.0f:%05.2f', x_tick_minutes', x_tick_seconds');
else
        labels = compose('%.0f:%04.1f', x_tick_minutes', x_tick_seconds');
end

xticks(axes, x_tick)
xticklabels(axes,labels);
end

