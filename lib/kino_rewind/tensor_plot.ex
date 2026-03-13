defmodule KinoRewind.TensorPlot do
  alias VegaLite, as: Vl

  @color_schemes [
    :accent,
    :category10,
    :category20,
    :category20b,
    :category20c,
    :observable10,
    :dark2,
    :paired,
    :pastel1,
    :pastel2,
    :set1,
    :set2,
    :set3,
    :tableau10,
    :tableau20,
    :blues,
    :tealblues,
    :teals,
    :greens,
    :browns,
    :oranges,
    :reds,
    :purples,
    :warmgreys,
    :greys,
    :viridis,
    :magma,
    :inferno,
    :plasma,
    :cividis,
    :turbo,
    :bluegreen,
    :bluepurple,
    :goldgreen,
    :goldorange,
    :goldred,
    :greenblue,
    :orangered,
    :purplebluegreen,
    :purpleblue,
    :purplered,
    :redpurple,
    :yellowgreenblue,
    :yellowgreen,
    :yelloworangebrown,
    :yelloworangered,
    :darkblue,
    :darkgold,
    :darkgreen,
    :darkmulti,
    :darkred,
    :lightgreyred,
    :lightgreyteal,
    :lightmulti,
    :lightorange,
    :lighttealblue,
    :blueorange,
    :brownbluegreen,
    :purplegreen,
    :pinkyellowgreen,
    :purpleorange,
    :redblue,
    :redgrey,
    :redyellowblue,
    :redyellowgreen,
    :spectral,
    :rainbow,
    :sinebow
  ]

  def plot(tensors, args \\ [])

  def plot(tensor = %Nx.Tensor{}, args) do
    plot([tensor], args)
  end

  def plot(tensors = [_h | _t], args) do
    plot_size = Keyword.get(args, :size, 300)

    tensors =
      for t <- tensors do
        {frames, channels, width, height} =
          case Nx.shape(t) do
            {f, 1, w, h} -> {f, 1, w, h}
            {f, 3, w, h} -> {f, 3, w, h}
            {1, w, h} -> {1, 1, w, h}
            {3, w, h} -> {1, 3, w, h}
            {f, w, h} -> {f, 1, w, h}
            {w, h} -> {1, 1, w, h}
          end

        Nx.reshape(t, {frames, channels, width, height})
      end

    max_frame = Enum.map(tensors, &elem(Nx.shape(&1), 0)) |> Enum.max()

    plots =
      for {t, ti} <- tensors |> Enum.with_index() do
        {frames, channels, _width, _height} = Nx.shape(t)
        {enc, _bits} = Nx.type(t)
        multiplier = if(enc == :f, do: 255, else: 1)

        imgData =
          t
          |> Nx.transpose(axes: [0, 2, 3, 1])
          |> Nx.to_list()
          |> Enum.with_index()
          |> Enum.flat_map(fn {frame, fi} ->
            frame
            |> Enum.with_index()
            |> Enum.flat_map(fn
              {row, ri} ->
                Enum.with_index(row)
                |> Enum.map(fn
                  {[r, g, b | _alpha], ci} ->
                    %{
                      x: ci,
                      y: ri,
                      color:
                        %Colorex.RGB{
                          red: r * multiplier,
                          green: g * multiplier,
                          blue: b * multiplier
                        }
                        |> to_string(),
                      frame: fi + 1,
                      last_frame: fi + 1 == frames
                    }

                  {v, ci} ->
                    %{
                      x: ci,
                      y: ri,
                      color: v,
                      frame: fi + 1,
                      last_frame: fi + 1 == frames
                    }
                end)
            end)
          end)

        plot =
          Vl.new(
            width: plot_size,
            height: plot_size,
            title: Keyword.get(args, :labels, []) |> Enum.at(ti, "Image #{ti + 1}")
          )
          |> Vl.data_from_values(imgData)
          |> Vl.mark(:rect)
          |> Vl.encode(:x, field: :x, type: :ordinal, axis: nil)
          |> Vl.encode(:y, field: :y, type: :ordinal, axis: nil)
          |> Vl.transform(
            filter: "datum.frame == frame || (datum.frame < frame && datum.last_frame)"
          )

        case channels do
          3 ->
            plot |> Vl.encode(:color, field: :color, type: :nominal, scale: nil)

          1 ->
            plot
            |> Vl.encode(:color,
              field: :color,
              type: :quantitative,
              scale: %{
                domain: [
                  Keyword.get(args, :vmin, Nx.round(Nx.reduce_min(t)) |> Nx.to_number()),
                  Keyword.get(args, :vmax, Nx.round(Nx.reduce_max(t)) |> Nx.to_number())
                ],
                scheme: [expr: "col"]
              },
              legend: %{
                orient: :right,
                title: nil,
                offset: 10,
                padding: 0,
                titleFontSize: 30,
                labelFontSize: 20
              }
            )
        end
      end

    Vl.new(
      title: Keyword.get(args, :titel, "Images"),
      config: [legend: [gradient_length: plot_size]],
      columns: Keyword.get(args, :columns, nil)
    )
    |> Vl.concat(plots, Keyword.get(args, :concat, :wrappable))
    |> Vl.param("frame",
      value: 1,
      bind:
        if(max_frame > 1,
          do: [
            name: Keyword.get(args, :time_label, "Frame"),
            input: :range,
            min: 1,
            max: max_frame,
            step: 1
          ]
        )
    )
    |> Vl.param("col",
      value: Keyword.get(args, :cmap, :viridis),
      bind:
        Keyword.get(args, :cmaps, @color_schemes)
        |> case do
          [f | _] = opts ->
            cmap = Keyword.get(args, :cmap, f)

            [
              name: "Color Scheme",
              input: :select,
              options: [cmap | opts |> Enum.reject(&(to_string(&1) == to_string(cmap)))]
            ]

          _ ->
            nil
        end
    )
    |> Vl.resolve(:scale, color: :independent, stroke: :independent, fill: :independent)
  end
end
