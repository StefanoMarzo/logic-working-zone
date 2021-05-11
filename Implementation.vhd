-- Progetto finale di Reti Logiche
-- Stefano Marzo
-- 10522922
-- Politecnico di Milano

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is  
    Port (  
    i_clk : in  std_logic;
    i_start : in  std_logic;
    i_rst : in  std_logic;  
    i_data : in  std_logic_vector(7 downto 0);                            -- segnale che arriva dalla memoria in seguito ad una richiesta di lettura
    o_address : out std_logic_vector(15 downto 0) := "0000000000000000";  -- segnale di uscita che manda l'indirizzo che vogliamo leggere alla memoria.
    o_done : out std_logic := '0';   
    o_en : out std_logic := '0';                                          -- segnale di ENABLE da dover mandare alla memoria per poter comunicare (sia in lettura che in scrittura)
    o_we : out std_logic := '0';                                          -- segnale di WRITE ENABLE da dover mandare alla memoria (=1) per poter scriverci. Per leggere da memoria esso deve essere 0
    o_data : out std_logic_vector (7 downto 0) := "11111111"              -- segnale di uscita dal componente verso la memoria (indirizzo codificato)
    ); 
end project_reti_logiche;
    
architecture description of project_reti_logiche is 

function sub_to_onehot(a, b : UNSIGNED)
    return STD_LOGIC_VECTOR is
    begin
        case a - b is
        
        when "00000011" => return "1000";
        when "00000010" => return "0100";
        when "00000001" => return "0010";
        when "00000000" => return "0001";
        
        when others => return "1111";
       
        end case;
end sub_to_onehot;


type machine_state is (
    start_reset, 
    leggi_indirizzo_da_valutare,
    leggi_cella_contatore, 
    carica_indirizzo_da_ram,
    controlla_working_zone, 
    aggiorna_contatore,
    trasforma_indirizzo,
    scrivi_indirizzo
    );
    
    signal current_state, next_state : machine_state;
    
    signal indirizzo_da_valutare : UNSIGNED(7 downto 0) := "00000000";  
    signal contatore : UNSIGNED (2 downto 0) := "000";
    signal contenuto_cella : UNSIGNED (7 downto 0) := "00000000";
    signal indirizzo_da_scrivere : STD_LOGIC_VECTOR(7 downto 0) := "00000000"; 
    signal wz_bit : STD_LOGIC := '0';
    
    constant DWZ : unsigned(2 downto 0) := "100";
        
    begin
    
    
    
    next_state_process: process(i_clk, i_rst)

    begin

    if(i_rst= '1') then
        current_state <= start_reset;
    elsif(rising_edge(i_clk)) then
        current_state <= next_state;
    end if;
    
    end process;
    
           
    
    Fsm: process(i_clk, i_start)
    
    begin
    
    if(i_start = '0') then o_done <= '0';
    elsif(falling_edge(i_clk) and i_start= '1') then
    case current_state is
        
        when start_reset =>
            o_en <= '1';
            o_we <= '0';
            o_data <= "11111111";
            contatore <= "000";
            o_address <= "0000000000001000"; -- legge da ram contenuto dell'indirizzo #8
            next_state <= leggi_indirizzo_da_valutare;
            
        when leggi_indirizzo_da_valutare =>
            
            if (i_data(7) = '1') then
                indirizzo_da_valutare <= "11111111";
                next_state <= scrivi_indirizzo; 
            else --se i_data > 127 -> errore
                indirizzo_da_valutare <= UNSIGNED(i_data);
                next_state <= leggi_cella_contatore; 
            end if;
        
        when leggi_cella_contatore =>
            o_en <= '1';
            o_we <= '0';
            o_address (15 downto 3) <= "0000000000000";
            o_address (2 downto 0) <= STD_LOGIC_VECTOR(contatore); -- richiede di leggere da ram indirizzo codificato da contatore
            next_state <= carica_indirizzo_da_ram;
        
        when carica_indirizzo_da_ram =>
            contenuto_cella <= UNSIGNED(i_data);
            next_state <= controlla_working_zone;
                        
        when controlla_working_zone =>
            o_en <= '0';
            if(indirizzo_da_valutare >= contenuto_cella and indirizzo_da_valutare < contenuto_cella + DWZ) then
                wz_bit <= '1';
                next_state <= trasforma_indirizzo;
            else 
                wz_bit <= '0';
                next_state <= aggiorna_contatore;
            end if;
          
        
        when aggiorna_contatore =>
            if(contatore = "111") then next_state <= scrivi_indirizzo; 
            else 
                contatore <= contatore + 1;
                next_state <= leggi_cella_contatore;
            end if;
        
        when trasforma_indirizzo =>
                    
            indirizzo_da_scrivere(7) <= WZ_BIT;
            indirizzo_da_scrivere(6 downto 4) <= STD_LOGIC_VECTOR(contatore);
            indirizzo_da_scrivere(3 downto 0) <= sub_to_onehot(indirizzo_da_valutare, contenuto_cella);
            next_state <= scrivi_indirizzo;
        
        when scrivi_indirizzo =>
        
            o_address <= "0000000000001001"; --indirizzo di ram #9
            o_en <= '1'; 
            o_we <= '1'; --abilito scrittura
            if(WZ_BIT = '1') then
            o_data <= indirizzo_da_scrivere;
            else o_data <= std_logic_vector(indirizzo_da_valutare);
            end if;
            o_done <= '1';
            next_state <= start_reset;
                        
            
        
    end case;
        
    end if;
    
    end process;
    
end description;
    