#include "protheus.ch"

/*/{Protheus.doc} TRETE013
Realiza atualização do Status LMC.
@author Totvs TBC
@since 25/07/2016
@version 1.0
@return ${return}, ${return_description}
@type function
/*/

User Function TRETE013()

Local oSay1, oSay2, oSay3
Local oButton1, oButton2

Private oStLmc
Private cStLmc := Space(1)

Static oDlgStLmc

DEFINE MSDIALOG oDlgStLmc TITLE "Status LMC" From 0,0 TO 140,400 PIXEL

@ 005,005 SAY oSay1 PROMPT "Situação atual: " SIZE 040, 007 OF oDlgStLmc COLORS 0, 16777215 PIXEL
@ 005,050 SAY oSay2 PROMPT IIF(Empty(SF1->F1_XLMC) .Or. SF1->F1_XLMC == "N","nao compoe"," sim compoe") SIZE 040, 007 OF oDlgStLmc COLORS 0, 16777215 PIXEL
@ 018,005 SAY oSay3 PROMPT "Novo status:" SIZE 040, 007 OF oDlgStLmc COLORS 0, 16777215 PIXEL
@ 018,050 MSCOMBOBOX oStLmc VAR cStLmc ITEMS {"N=Nao compoe","S=Sim compoe"} SIZE 070, 010 OF oDlgStLmc COLORS 0, 16777215 PIXEL

//Linha horizontal
@ 040, 005 SAY oSay2 PROMPT Repl("_",186) SIZE 186, 007 OF oDlgStLmc COLORS CLR_GRAY, 16777215 PIXEL

//Botoes
@ 051, 100 BUTTON oButton1 PROMPT "Confirmar" SIZE 040, 010 OF oDlgStLmc ACTION ConfStLmc() PIXEL  
@ 051, 150 BUTTON oButton2 PROMPT "Fechar" SIZE 040, 010 OF oDlgStLmc ACTION oDlgStLmc:End() PIXEL  

ACTIVATE MSDIALOG oDlgStLmc CENTERED

Return

/**************************/
Static Function ConfStLmc()
/**************************/

If oStLmc:nAt == 1 //N=Nao
            
    If MsgYesNo("O Documento de Entrada passará a não compor LMC relacionado, deseja continuar?")
     	
     	RecLock("SF1",.F.)
		SF1->F1_XLMC := "N"     	
     	SF1->(MsUnlock())
	Endif
	                                                                                           
Else //S=Sim

    If MsgYesNo("O Documento de Entrada passará a compor LMC relacionado, deseja continuar?")
    
     	RecLock("SF1",.F.)
		SF1->F1_XLMC := "S"     	
     	SF1->(MsUnlock())
	Endif
Endif                     

MsgInfo("Status LMC atualizado.","Atenção")  

oDlgStLmc:End()

Return