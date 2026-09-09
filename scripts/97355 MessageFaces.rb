module PFM
    module Message
        class Properties
            PROPERTIES["pkmn_face"] = :parse_pkmn_face
            # Get all the faces to show
            # @return [Array<Face>]
            attr_reader :dungeon_mystery_faces

            def initialize(parsed_text)
                @parsed_text = parsed_text
                @show_gold_window = false
                @can_skip_message = false
                @name = nil
                @name_color = nil
                @faces = []
                @dungeon_mystery_faces = []
                @align = :left
                preparse_properties
            end

            def parse_pkmn_face(info_str)
                info_message, info_pokemon = info_str.split('!')
                position, expression, mirror, opacity = info_message.split(',')
                pkmn_id, pkmn_form, female, shiny = info_pokemon.split(',')
                face = PkmnFace.new

                position.strip!
                expression.strip!

                if position == "right" 
                    face.position = -10
                elsif position == "left"
                    face.position = 10
                else
                    face.position = position.to_i
                end  
                face.set_pkmn_id(pkmn_id)
                face.opacity = opacity && opacity != "" ? opacity.to_i.clamp(0, 255) : 255
                face.mirror = mirror == "true"
                face.pkmn_form = pkmn_form ? pkmn_form.capitalize().strip : ""
                face.female = (female == "true")
                face.shiny = (shiny == "true")
                face.expression = expression.capitalize()
                

                face.compute_directory()
                @dungeon_mystery_faces << face
            end

            class PkmnFace
                # Get the face position
                # @return [Integer]
                attr_accessor :position
                # Get the pokemon id in format "0000"
                # @return [String]
                attr_accessor :pkmn_id
                # Get the form of the pokemon
                # @return [Boolean]
                attr_accessor :pkmn_form
                # Get if the pokemn is female
                # @return [Boolean]
                attr_accessor :female
                # Get if the pokemn is shiny
                # @return [Boolean]
                attr_accessor :shiny
                # Get the face opacity
                # @return [Integer]
                attr_accessor :opacity
                # Get the face mirror state
                # @return [Boolean]
                attr_accessor :mirror
                # Get the directory inside the pkmn_id repertory
                # @return [String]
                attr_reader :directory
                # Get the expresson of the face
                # @return [String]
                attr_accessor :expression
                
                def PkmnFace.parse_tracker(tracker_json)
                    tracker_result = {}
                    tracker_json.each do |pkmn_face_info|
                        pkmn_id = pkmn_face_info[0]
                        names = parse_subgroup(pkmn_face_info[1],previous_name = "", path ="", first_iteration = true)
                        tracker_result[pkmn_id] = names
                    end
                    return tracker_result
                end
                
                def PkmnFace.parse_subgroup(curr_subgroup, previous_name = "", path ="", first_iteration = false)
                    names = {}
                    if curr_subgroup["name"] == "Shiny" or curr_subgroup["name"] == "Female"
                        curr_name = previous_name +"_"+ curr_subgroup["name"]
                    else
                        curr_name = curr_subgroup["name"]
                    end 
                    if first_iteration 
                        curr_name = ""
                    end

                    curr_expressions = curr_subgroup["portrait_files"].map {|expression, locked| expression}
                    if curr_subgroup["name"] != "" && curr_expressions.length() != 0
                        names[curr_name.capitalize] = {"path" => path, "expressions" => curr_expressions}
                    end
                    subgroups = curr_subgroup["subgroups"]
                    subgroups.each do |subgroup_child|
                        new_path = File.join(path, subgroup_child[0])
                        names = names.merge(parse_subgroup(subgroup_child[1], curr_name, new_path))
                    end
                    return names
                end

                
                file_tracker_content = File.read(File.join('graphics', 'pictures', 'pkmn_faces', "tracker.json"))
                pkmn_faces_tracker_raw = JSON.parse(file_tracker_content)
                @@pkmn_faces_tracker = parse_tracker(pkmn_faces_tracker_raw)

              
                @@expressions_converter = 
                {
                    "Normal" => ["Normal"],
                    "Happy" =>["Joyous","Inspired", "Normal"],
                    "Pain" => ["Stunned", "Sad", "Dizzy", "Crying", "Normal"],
                    "Angry" => ["Determined", "Shouting", "Normal"],
                    "Worried" => ["Teary-Eyed", "Stunned", "Sigh", "Normal"],
                    "Sad" => ["Crying", "Teary-Eyed", "Pain", "Normal"],
                    "Crying" => ["Sad", "Teary-Eyed", "Pain", "Normal"],
                    "Shouting"=>["Determined", "Surprised", "Angry", "Normal"],
                    "Teary-Eyed" => ["Sad", "Crying", "Worried", "Normal"],
                    "Determined" => ["Angry", "Shouting", "Normal"],
                    "Joyous" => ["Happy", "Inspired", "Normal"],
                    "Inspired" => ["Happy", "Joyous", "Normal"],
                    "Surprised" => ["Stunned", "Pain", "Normal"],
                    "Dizzy" => ["Stunned", "Pain", "Normal"],
                    "Special0" => ["Normal"],
                    "Special1" => ["Normal"],
                    "Sigh" => ["Pain", "Normal"],
                    "Stunned" => ["Surprised", "Dizzy", "Normal"],
                    "Special2" => ["Normal"],
                    "Special3" => ["Normal"] 
                }

                def set_pkmn_id(pkmn_id)
                    if pkmn_id.to_i == 0
                        pkmn_id =data_creature(pkmn_id.to_sym).id.to_s
                    end
                    @pkmn_id = pkmn_id.rjust(4, "0")
                end
                
                def compute_directory()
                    current_face_infos = @@pkmn_faces_tracker[@pkmn_id]
                    expressions_list = [@expression] + @@expressions_converter[@expression]
                    expression_found = false
                    expression_index = 0
                    while (expression_found == false && expression_index < expressions_list.length)
                        expression = expressions_list[expression_index]
                    
                        if @pkmn_form == ""
                            unless try_all_faces_possibilities(current_face_infos, "Alternate", expression)
                                unless try_all_faces_possibilities(current_face_infos, "AltColor", expression)
                                    expression_found = try_all_faces_possibilities(current_face_infos, "", expression)
                                else
                                    expression_found = true
                                end
                            else
                                expression_found = true
                            end
                        else
                            expression_found = try_all_faces_possibilities(current_face_infos, @pkmn_form, expression)
                        end
                        expression_index = expression_index + 1
                    end
                end

                def try_all_faces_possibilities(face_infos, name_face, expression)
                    if @shiny 
                        name_face = name_face + "_shiny"
                    end
                    if @female
                        if face_infos.has_key?(name_face + "_female")
                            name_face = name_face + "_female"
                        end
                    end

                    if face_exist?(face_infos, name_face, expression)
                        if @mirror && face_exist?(face_infos, name_face, expression + "^")
                            @directory = File.join(face_infos[name_face]["path"], expression + "^")
                            @mirror = false
                        else
                            @directory = File.join(face_infos[name_face]["path"], expression)
                        end
                        return true
                    end
                    return false
                end

                def face_exist?(face_infos, name_face, name_expression)
                    unless face_infos.has_key?(name_face) 
                        return false
                    end
                    expressions = face_infos[name_face]["expressions"]
                    unless expressions.include?(name_expression)
                        return false
                    end
                    return true
                end

                
                def get_directory
                    if @directory.nil?
                        return ""
                    end
                    return @directory
                end
                
            end
        end
    end
end

module UI
    # Module responsive of holding the whole message ui aspect
    module Message
        # Module defining the Message layout
        module Layout
            def show_pkmn_face(pkmn_face)
                sprite = Sprite.new(viewport)
                path = File.join("pkmn_faces", "portrait", pkmn_face.pkmn_id, pkmn_face.get_directory)
                sprite.load(path, :picture)

                if pkmn_face.position <0
                    pkmn_face.position = pkmn_face.position - sprite.width
                end
                sprite.set_position(parse_speaker_position(pkmn_face.position), face_pkmn_y(sprite.height))
                #sprite.set_origin(sprite.width / 2, sprite.height)
                def sprite.opacity=(v)
                return @opacity = v unless @opacity
                super(v * @opacity / 255)
                end
                sprite.opacity = pkmn_face.opacity
                sprite.mirror = pkmn_face.mirror
                @sub_stack.push_sprite(sprite)

                sprite_window_face = Sprite.new(viewport)
                sprite_window_face.load("window_pkmn_face", :interface)
                sprite_window_face.set_position(parse_speaker_position(pkmn_face.position)-3, face_pkmn_y(sprite.height)-3)
                @sub_stack.push_sprite(sprite_window_face)
            end

            def face_pkmn_y(sprite_height)
                wb = current_window_builder
                return y + (current_position == :top ? height + default_vertical_margin + 3 : (-sprite_height - default_vertical_margin - 3))
                return viewport.rect.height - height - 10
            end

            def load_sub_layout
                @sub_stack.dispose
                properties.faces.each { |face| show_face(face) }
                properties.dungeon_mystery_faces.each { |pkmn_face| show_pkmn_face(pkmn_face) }
                show_name_window if properties.name
                show_city_image if properties.city_filename
                show_gold_window if properties.show_gold_window
                properties.process_look_to
                viewport.sort_z
            end
        end
    end
end

class Interpreter < Interpreter_RMXP
    def get_pkmn_data_for_pkmn_face(pokemon)
        pkmn_id = pokemon.id.to_s
        female = pokemon.female?
        shiny = pokemon.shiny?

        return [pkmn_id, pkmn_form(pokemon), female, shiny].join(",")
    end

    def pkmn_form(pokemon)
        pkmn_form_id = pokemon.form
        if pkmn_form_id == 0
            return ""
        end
        form_id = pokemon.get_data().form_text_id.name
        english_name_form = Studio::Text.get_english_name_form(form_id)
        
        decomposed_name_form = english_name_form.split(" ")
        correct_form_names = ["Mega", "Primal", "Gigantamax", 
        "Therian", # les génies
        "Origin", 
        "East", # Sancoki/tritosor
        "Sky", # Shaymin
        "School", # Froussardine
        "Ultra", #
        "Hangry", # Morpeko
        "Dada", 
        "Hero", # Superdofin
        "Terastal", 
        "Stellar"]
        return_text = ""
        if correct_form_names.include?(decomposed_name_form[0])
            return_text = decomposed_name_form[0]

            if decomposed_name_form[0] == "Mega"
                if decomposed_name_form.length() >= 3 
                    if decomposed_name_form[2] == "X"
                       return_text = "Mega_X"
                    elsif decomposed_name_form[2] == "Y"
                        return_text = "Mega_Y"
                    end
                end
            end
        else
            case decomposed_name_form[0]
            when "Alolan"
                return_text = "Alola"
            when "Galarian"
                return_text = "Galar"
            when "Hisuian"
                return_text = "Hisui"            
            when "Paldean"
                return_text = "Paldea"
            end
        end

        # cas speciaux à traiter => pikachu, zarbi, mega mewtwo, morphéo, deoxys, cheniti/cheniselle, ceriflor
        # motisma, arceus, bargantua, darumacho, vivaldaim, kyurem, meloetta, keldeo, genesect, prismillon,
        # couafarel (pas de sprites), exagide, zygarde, hoopa, plumeline, lougaroc
        # silvallié, météno, nécrozma, salarsen, zacian/zamazenta, shifours, silveroy, paragruel (??)
        # famignol, tapatoes, nigirigon, deusolourdo, mordudor, ogerpon, charmilly
        return return_text
    end
end

module Studio
    module Text
        module_function
        def get_english_name_form(form_id)
            file_id = CSV_BASE + 67
            if File.exist?(filename = format('Data/Text/Dialogs/%<file_id>d.csv', file_id: file_id))
                rows = CSV.read(filename)
                lang_index = 0

                return build_dialog_from_csv_rows(rows, lang_index)[form_id]
            end
            return nil
        end
    end
end
        