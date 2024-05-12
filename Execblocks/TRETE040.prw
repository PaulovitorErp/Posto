#include "protheus.ch"

Static cTabSX5Mot := SuperGetMV("MV_XX5MEXF",,"Z5")

/*/{Protheus.doc} TRETE040
Log Exclusão Fatura
@author Maiki Perin
@since 01/09/2020
@version P12
@param nTipo: 1=Exclusao Fatura;2=Exclusao Renegociação;3=Renegociação
@return nulo
/*/

/************************************************/
User Function TRETE040(nTipo,aDadosFat,aDadosLog, lAuto)
/************************************************/

Local oButton1
Local oSay1, oSay2, oSay3

Local oMotivo
Local oObs
Local cMotivo		:= Space(TamSX3("U0J_MOTIVO")[1])
Local cObs		    := Space(TamSX3("U0J_OBS")[1])
Local aDsTipo       := {"Exclusão de Fatura","Exclusão Renegociação","Renegociação"}

Default lAuto   := .F.
Default aDadosLog   := {}

Private oDescMot
Private cDescMot	:= ""
Private lImpFechar	:= .F.

Static oDlgLog

If !lAuto // Primeira execução

	DEFINE MSDIALOG oDlgLog TITLE ("Selecionar o motivo para "+aDsTipo[nTipo]) From 000,000 TO 115,400 PIXEL

	@ 005, 005 SAY oSay1 PROMPT "Motivo:" SIZE 040, 007 OF oDlgLog COLORS CLR_BLUE, 16777215 PIXEL
	@ 005, 040 MSGET oMotivo VAR cMotivo SIZE 040, 010 OF oDlgLog COLORS 0, 16777215 HASBUTTON PIXEL Valid IIF(!Empty(cMotivo),ValMot(cMotivo),.T.) F3 cTabSX5Mot Picture "@!"
	@ 006, 085 SAY oDescMot PROMPT cDescMot SIZE 120, 007 OF oDlgLog COLORS 0, 16777215 PIXEL
	@ 018, 005 SAY oSay2 PROMPT "Observação:" SIZE 040, 007 OF oDlgLog COLORS 0, 16777215 PIXEL
	@ 018, 040 MSGET oObs VAR cObs SIZE 157, 010 OF oDlgLog COLORS 0, 16777215 PIXEL Picture "@!"

    // Linha horizontal
	@ 030, 005 SAY oSay3 PROMPT Repl("_",190) SIZE 190, 007 OF oDlgLog COLORS CLR_GRAY, 16777215 PIXEL

	@ 041, 155 BUTTON oButton1 PROMPT "Confirmar" SIZE 040, 010 OF oDlgLog ACTION GrvLog(nTipo,aDadosFat,{{cMotivo,cObs}},lAuto) PIXEL

	ACTIVATE MSDIALOG oDlgLog CENTERED VALID lImpFechar

Else // Execuções posteriores
    GrvLog(nTipo,aDadosFat,aDadosLog,lAuto)
EndIf

Return {{cMotivo,cObs}}

/******************************/
Static Function ValMot(cMotivo)
/******************************/

Local lRet := .T.

DbSelectArea("SX5")
SX5->(DbSetOrder(1)) // X5_FILIAL+X5_TABELA+X5_CHAVE

If !Empty(cMotivo)

    If !SX5->(DbSeek(xFilial("SX5")+cTabSX5Mot+cMotivo))

        MsgInfo("Motivo inválido.","Atenção")
        cDescMot := ""
        lRet := .F.
    Else
        cDescMot := SX5->X5_DESCRI
    Endif
Else
    cDescMot := ""
Endif

oDescMot:Refresh()

Return lRet

/************************************************/
Static Function GrvLog(nTipo,aDadosFat,aDadosLog,lAuto)
/************************************************/

Local nX

If !Empty(aDadosLog[1][1])

    DbSelectArea("U0J")

    for nX := 1 to len(aDadosFat)

        RecLock("U0J",.T.)
        U0J->U0J_FILIAL := xFilial("U0J")
        U0J->U0J_PROCES := cValToChar(nTipo)
        U0J->U0J_PREFIX := aDadosFat[nX][1]
        U0J->U0J_NUM    := aDadosFat[nX][2]
        U0J->U0J_PARCEL := aDadosFat[nX][3]
        U0J->U0J_TIPO   := aDadosFat[nX][4]
        U0J->U0J_MOTIVO := aDadosLog[1][1]
        U0J->U0J_OBS    := aDadosLog[1][2]
        U0J->U0J_USER   := cUserName
        U0J->U0J_DATA   := Date()
        U0J->U0J_HORA   := Transform(Time(),"@R 99:99")
        U0J->(MsUnlock())

    next nX

    If !lAuto // Primeira execução
        //MsgInfo("Motivo incluído com sucesso.","Atenção")
        lImpFechar := .T.
        oDlgLog:End()
    EndIf
Else
    MsgInfo("Campo [Motivo] obrigatório.","Atenção")
EndIf

Return
