{ ... }:

{
  programs.wofi = {
    enable = true;
  };

  # Wofi Konfiguration
  xdg.configFile."wofi/config".text = ''
    show=drun
    prompt=Search…
    width=420
    height=520
    allow_images=true
    insensitive=true
    no_actions=true
  '';

  # Wofi Style (aus deinem style.css übernommen)
  xdg.configFile."wofi/style.css".text = ''
    /* The name of the window itself */
    #window {
      background-color: rgba(24, 24, 24, 0.6);
      backdrop-filter: blur(10px);
      -webkit-backdrop-filter: blur(10px);
      box-shadow: 0 18px 40px rgba(0, 0, 0, 0.55),
            0 6px 14px rgba(0, 0, 0, 0.35);

      border-radius: 1rem;
      font-size: 1.2rem;
    }

    /* The name of the box that contains everything */
    #outer-box {
    }

    /* The name of the search bar */
    #input {
      background-color: rgba(24, 24, 24, 0.6);
      color: #f2f2f2;
      border: none;
      border-bottom: 1px solid rgba(24, 24, 24, 0.2);
      padding: 0.8rem 1rem;
      font-size: 1.5rem;
      border-radius: 1rem 1rem 0 0;
    }

    #input:focus,
    #input:focus-visible,
    #input:active {
      border: none;
      outline: 2px solid transparent;
      outline-offset: 2px;
    }

    /* The name of the scrolled window containing all of the entries */
    #scroll {
    }

    /* The name of the box containing all of the entries */
    #inner-box {
    }

    /* The name of all entries */
    #entry {
      color: #ffffff;
      background-color: rgba(24, 24, 24, 0.1);
      padding: 0.6rem 1rem;
    }

    /* The name of all images in entries displayed in image mode */
    #entry #img {
      width: 1rem;
      margin-right: 0.5rem;
    }

    /* The name of all the text in entries */
    #entry #text {
    }

    #entry:selected {
      color: #ffffff;
      background-color: rgba(255, 255, 255, 0.1);
      outline: none;
    }
  '';
}

