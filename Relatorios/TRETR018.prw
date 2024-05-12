#include "protheus.ch"
#include "topconn.ch"

Static cTabSX5Mot := SuperGetMV("MV_XX5MEXF",,"Z5")

/*/{Protheus.doc} TRETR018
Relatório Log de Faturas
@author Maiki Perin
@since 08/09/2020
@version P12
@param Nao recebe parametros
@return nulo
/*/

/***********************/
User Function TRETR018(nOpcX)
/***********************/

Local oReport

Default nOpcX := 1 

Private nQtdT := 0

U_uAjusSx1("TRETR018","01","De Filial ?","","","mv_ch0","C",len(cFilAnt),0,0,"G","","SM0","","","mv_par01","","","",space(len(cFilAnt)),"","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uAjusSx1("TRETR018","02","Até Filial ?","","","mv_ch1","C",len(cFilAnt),0,0,"G","","SM0","","","mv_par02","","","",Replicate("Z",len(cFilAnt)),"","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uAjusSx1("TRETR018","03","De Data ?","","","mv_ch2","D",10,0,0,"G","","","","","mv_par03","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uAjusSx1("TRETR018","04","Até Data ?","","","mv_ch3","D",10,0,0,"G","","","","","mv_par04","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uAjusSx1("TRETR018","05","Motivo ?","","","mv_ch4","C",06,0,0,"G","",cTabSX5Mot,"","","mv_par05","","","","","","","","","","","","","","","","",  {"",""},{"",""},{"",""})
U_uAjusSx1("TRETR018","06","Usuario ?","","","mv_ch5","C",25,0,0,"G","","US3","","","mv_par06","","","","","","","","","","","","","","","","",  {"",""},{"",""},{"",""})
U_uAjusSx1("TRETR018","07","Num Titulo ?","","","mv_ch6","C",9,0,0,"G","","","","","mv_par07","","","","","","","","","","","","","","","","",  {"",""},{"",""},{"",""})
U_uAjusSx1("TRETR018","08","Processo ?","","","mv_ch7","N",1,0,0,"C","","","","","mv_par08","Todos","","","","Exc.Fatura","","","Exc.Reneg.","","","Renegociação","","","Env.Email","","",  {"",""},{"",""},{"",""})

if nOpcX == 1 //relatório
    oReport:= ReportDef()
    oReport:PrintDialog()
else //em tela

    if Pergunte("TRETR018",.T.)
        TelaLogFat()
    endif

endif

Return

/**************************/
Static Function ReportDef()
/**************************/

Local oReport

Local oSection1, oSection2, oSection3
Local oBreak1
Local oQtd

Local cTitle := "Log de Faturas"

oReport:= TReport():New("TRETR018",cTitle,"TRETR018",{|oReport| PrintReport(oReport,oSection1,oSection2,oSection3)},;
                        "Este relatório apresenta Log de ações realizadas de Faturas.")
//oReport:SetPortrait()
oReport:SetLandscape()
oReport:HideParamPage()
oReport:SetUseGC(.F.) //Desabilita o botão <Gestao Corporativa> do relatório
oReport:DisableOrientation()
//oReport:lBold := .T.

Pergunte(oReport:uParam,.F.)

// Seção 1 - Filial
oSection1 := TRSection():New(oReport,"Filial",{""})
oSection1:SetHeaderPage(.F.)
oSection1:SetHeaderSection(.T.)
oSection1:SetPageBreak(.F.)
TRCell():New(oSection1,"M0_CODFIL"	,"", "FILIAL",			"@!",	FWSizeFilial()+1)
TRCell():New(oSection1,"M0_FILIAL"	,"", "NOME",			"@!",	41)

// Seção 2 - Log
oSection2 := TRSection():New(oReport,"Log",{"QRYLOG"})
oSection2:SetHeaderPage(.F.)
oSection2:SetHeaderSection(.T.)
oSection2:SetTotalInLine(.F.)

TRCell():New(oSection2,"U0J_PROCES" ,"QRYLOG",   "PROCESSO", 		PesqPict("U0J","U0J_PROCES"),021)
TRCell():New(oSection2,"U0J_PREFIX" ,"QRYLOG",   "PREFIXO", 		PesqPict("U0J","U0J_PREFIX"),TamSX3("U0J_PREFIX")[1])
TRCell():New(oSection2,"U0J_NUM"	,"QRYLOG",   "NO. TITULO", 		PesqPict("U0J","U0J_NUM"),TamSX3("U0J_NUM")[1])
TRCell():New(oSection2,"U0J_PARCEL"	,"QRYLOG",   "PARCELA",			PesqPict("U0J","U0J_PARCEL"),TamSX3("U0J_PARCEL")[1])
TRCell():New(oSection2,"U0J_TIPO"	,"QRYLOG",   "TIPO",            PesqPict("U0J","U0J_TIPO"),TamSX3("U0J_TIPO")[1])
TRCell():New(oSection2,"U0J_MOTIVO"	,"QRYLOG",   "MOTIVO",          PesqPict("U0J","U0J_MOTIVO"),TamSX3("U0J_MOTIVO")[1])
TRCell():New(oSection2,"X5_DESCRI"	,"QRYLOG",   "DESCRICAO",       PesqPict("SX5","X5_DESCRI"),TamSX3("X5_DESCRI")[1])
TRCell():New(oSection2,"U0J_OBS"	,"QRYLOG",   "OBSERVACAO",      PesqPict("U0J","U0J_OBS"), 080,,,,.T.)//TamSX3("U0J_OBS")[1]
TRCell():New(oSection2,"U0J_USER"	,"QRYLOG",   "USUARIO",         PesqPict("U0J","U0J_USER"),TamSX3("U0J_USER")[1])
TRCell():New(oSection2,"U0J_DATA"	,"QRYLOG",   "DATA",            PesqPict("U0J","U0J_DATA"),TamSX3("U0J_DATA")[1]+5)
TRCell():New(oSection2,"U0J_HORA"	,"QRYLOG",   "HORA",            PesqPict("U0J","U0J_HORA"),TamSX3("U0J_HORA")[1]+2)

oBreak1 := TRBreak():New(oSection1,{|| SM0->M0_CODFIL },"QTDE. FATURAS",.F.) 
oQtd    := TRFunction():New(oSection2:Cell("U0J_NUM"),"QTDDOCS","COUNT",oBreak1/*oBreak*/,,,,.F.,.F.,.F.)

oQtd:SetEndSection(.F.)

// Seção 3 - QTDE. GERAL DE FATURAS
oSection3 := TRSection():New(oReport,"QTDE GERAL",{""})
oSection3:SetHeaderPage(.F.)
oSection3:SetHeaderSection(.T.)
TRCell():New(oSection3,"QTDEG" ,"",   "QTDE. GERAL FATURAS", 		"@E 9,999,999,999,999",14)

Return(oReport)

/*****************************************************************/
Static Function PrintReport(oReport,oSection1,oSection2,oSection3)
/*****************************************************************/

Local cQry      := ""
Local nQtdeG    := 0
Local cFilAtual := ""
Local aDsTipo   := {"Exclusão de Fatura","Exclusão Renegociação","Renegociação","Envio Email"}
Local aObsEmail := {}

oReport:SetMeter(100)	

If Select("QRYLOG") > 0
    QRYLOG->(DbCloseArea())
EndIf     

cQry := MontaQuery()

//MemoWrite("c:\temp\TRETR018.txt",cQry)
TcQuery cQry New Alias "QRYLOG" 

If QRYLOG->(!EOF())
    
    oSection2:SetPageBreak(.F.)

    While !oReport:Cancel() .And. QRYLOG->(!EOF())
        
        oReport:IncMeter()
    
        If oReport:Cancel()
            Exit
        EndIf   

        if cFilAtual <> QRYLOG->U0J_FILIAL
            if !empty(cFilAtual)
                oSection2:Finish()
                oSection1:Finish()
            endif
            oSection1:Init()

            oSection1:Cell("M0_CODFIL"):SetValue(QRYLOG->U0J_FILIAL)
            oSection1:Cell("M0_FILIAL"):SetValue(FwFilialName(,QRYLOG->U0J_FILIAL))
            
            oSection1:PrintLine()

            oSection2:Init()
        endif

        oSection2:Cell("U0J_PROCES"):SetValue( iif(empty(QRYLOG->U0J_PROCES),"",aDsTipo[Val(QRYLOG->U0J_PROCES)]) )
        oSection2:Cell("U0J_PREFIX"):SetValue(QRYLOG->U0J_PREFIX)
        oSection2:Cell("U0J_NUM"):SetValue(QRYLOG->U0J_NUM)
        oSection2:Cell("U0J_PARCEL"):SetValue(QRYLOG->U0J_PARCEL)
        oSection2:Cell("U0J_TIPO"):SetValue(QRYLOG->U0J_TIPO)
        oSection2:Cell("U0J_MOTIVO"):SetValue(QRYLOG->U0J_MOTIVO)
        if Alltrim(QRYLOG->U0J_MOTIVO) == "EMAIL"
            U0J->(DbGoTo(QRYLOG->RECU0J))
            aObsEmail := STRTOKARR(U0J->U0J_DETAIL, CRLF)  
            oSection2:Cell("X5_DESCRI"):SetValue(QRYLOG->U0J_OBS)
            if len(aObsEmail)>=1
                oSection2:Cell("U0J_OBS"):SetValue(aObsEmail[1])
            else
                oSection2:Cell("U0J_OBS"):SetValue("")
            endif
        else
            oSection2:Cell("X5_DESCRI"):SetValue(QRYLOG->X5_DESCRI)
            oSection2:Cell("U0J_OBS"):SetValue(QRYLOG->U0J_OBS)
        endif
        oSection2:Cell("U0J_USER"):SetValue(QRYLOG->U0J_USER)
        oSection2:Cell("U0J_DATA"):SetValue(DToC(SToD(QRYLOG->U0J_DATA)))
        oSection2:Cell("U0J_HORA"):SetValue(QRYLOG->U0J_HORA)

        oSection2:PrintLine()

        nQtdeG++

        cFilAtual := QRYLOG->U0J_FILIAL

        QRYLOG->(DbSkip())
    EndDo

EndIf

oSection2:Finish()
oSection1:Finish()

oSection3:Init()
oSection3:Cell("QTDEG"):SetValue(nQtdeG)
oSection3:PrintLine()
oSection3:Finish()

If Select("QRYLOG") > 0
	QRYLOG->(DbCloseArea())
EndIf  

Return

Static Function MontaQuery()

    Local cQry      := ""

    cQry := " SELECT U0J.U0J_FILIAL,  "
    cQry += " U0J.U0J_PROCES,"
    cQry += " U0J.U0J_PREFIX,"
    cQry += " U0J.U0J_NUM,"
    cQry += " U0J.U0J_PARCEL,"
    cQry += " U0J.U0J_TIPO,"
    cQry += " U0J.U0J_MOTIVO,"
    cQry += " SX5.X5_DESCRI,"
    cQry += " U0J.U0J_OBS,"
    cQry += " U0J.U0J_USER,"
    cQry += " U0J.U0J_DATA,"
    cQry += " U0J.U0J_HORA,"
    cQry += " U0J.R_E_C_N_O_ AS RECU0J"
    cQry += " FROM "+RetSqlName("U0J")+" U0J LEFT JOIN "+RetSqlName("SX5")+" SX5 ON U0J.U0J_MOTIVO = SX5.X5_CHAVE"
    cQry += "                                                                 AND SX5.X5_TABELA = '"+cTabSX5Mot+"'"
    if len(alltrim(xFilial("SX5"))) <> len(alltrim(xFilial("U0J")))
        cQry += "                                                                 AND SX5.X5_FILIAL = '"+xFilial("SX5")+"' "
    else
        cQry += "                                                                 AND SX5.X5_FILIAL = U0J.U0J_FILIAL "
    endif
    cQry += "                                                                 AND SX5.D_E_L_E_T_  <> '*'"
    cQry += " WHERE U0J.D_E_L_E_T_  <> '*'"
    cQry += " AND U0J.U0J_FILIAL    BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"'"
    cQry += " AND U0J.U0J_DATA      BETWEEN '"+DToS(MV_PAR03)+"' AND '"+DToS(MV_PAR04)+"'"
    If !Empty(MV_PAR05)
        cQry += " AND U0J.U0J_MOTIVO      = '"+MV_PAR05+"'"
    EndIf
    If !Empty(MV_PAR06)
        cQry += " AND U0J.U0J_USER        = '"+MV_PAR06+"'"
    EndIf
    If !Empty(MV_PAR07)
        cQry += " AND U0J.U0J_NUM        = '"+MV_PAR07+"'"
    EndIf
    If MV_PAR08 > 1
        cQry += " AND U0J.U0J_PROCES        = '"+cValToChar(MV_PAR08-1)+"'"
    EndIf
    cQry += " ORDER BY U0J.U0J_FILIAL, U0J.U0J_PREFIX, U0J.U0J_NUM, U0J.U0J_PARCEL, U0J.U0J_TIPO, U0J.U0J_DATA, U0J.U0J_HORA"

    cQry := ChangeQuery(cQry)

Return cQry

Static Function TelaLogFat()

    Local cQry      := ""
    Local oSay1
    Local oSay2
    Local oSay3
    Local oSay4
    Local oSay5
    Local oSay6
    Local oSay7
    Local oGroup1
    Local oGroup2
    Local oFont1 := TFont():New("MS Sans Serif",,020,,.T.,,,,,.F.,.F.)
    Local aDsTipo   := {"Exclusão de Fatura","Exclusão Renegociação","Renegociação","Envio Email"}
    Local oGetFatur
    Local oGetFil
    Local oGetProcess
    Local oGetMovtivo
    Local oGetObs
    Local oListLogs
    Local nListLogs := 1
    Local oGetDetail
    Local oGetUser
    Local oGetData
    Local bCpRefresh := {|| oGetFatur:Refresh(), oGetFil:Refresh(), oGetProcess:Refresh(), oGetMovtivo:Refresh(), oGetObs:Refresh(), oGetDetail:Refresh(), oGetUser:Refresh(), oGetData:Refresh() }
    
    Private aLogsFat := {}

    Static oDlgLog

    cQry := MontaQuery()

    If Select("QRYLOG") > 0
        QRYLOG->(DbCloseArea())
    EndIf     

    cQry := MontaQuery()

    //MemoWrite("c:\temp\TRETR018.txt",cQry)
    TcQuery cQry New Alias "QRYLOG" 

    While QRYLOG->(!EOF())

        aadd(aLogsFat, {;
            QRYLOG->U0J_PREFIX + "-" + QRYLOG->U0J_NUM + "-" + QRYLOG->U0J_PARCEL, ;
            iif(empty(QRYLOG->U0J_PROCES),"Exclusão de Fatura",aDsTipo[Val(QRYLOG->U0J_PROCES)]),;
            DToC(SToD(QRYLOG->U0J_DATA)) + " " + QRYLOG->U0J_HORA,;
            QRYLOG->RECU0J ;
        })

        QRYLOG->(DbSkip())
    EndDo

    if empty(aLogsFat)
        MsgInfo("Não foi encontrado logs com os filtros selecionados!")
        Return
    endif

    U0J->(DbGoTo(aLogsFat[1][4]))

    DEFINE MSDIALOG oDlgLog TITLE "Log de Faturas" FROM 000, 000  TO 600, 500 COLORS 0, 16777215 PIXEL

    @ 003, 010 SAY oSay1 PROMPT "Log de Faturas" SIZE 226, 010 OF oDlgLog FONT oFont1 COLORS 0, 16777215 PIXEL

    @ 021, 008 GROUP oGroup1 TO 132, 245 PROMPT "Logs Encontrados" OF oDlgLog COLOR 0, 16777215 PIXEL
	
    @ 030, 009 LISTBOX oListLogs VAR nListLogs FIELDS HEADER "Titulo","Processo","Data/Hora" SIZE 235, 098 OF oDlgLog COLORS 0, 16777215 PIXEL NOSCROLL

    oListLogs:SetArray(aLogsFat)
	oListLogs:bLine := {|| {aLogsFat[oListLogs:nAT,1],aLogsFat[oListLogs:nAT,2],aLogsFat[oListLogs:nAT,3]} }
    oListLogs:bChange := {|| U0J->(DbGoTo(aLogsFat[oListLogs:nAT][4])), Eval(bCpRefresh) }

    @ 136, 008 GROUP oGroup2 TO 280, 245 PROMPT "Detalhe do log " OF oDlgLog COLOR 0, 16777215 PIXEL

    @ 150, 015 SAY oSay2 PROMPT "Fatura:" SIZE 025, 007 OF oDlgLog COLORS 0, 16777215 PIXEL
    @ 158, 015 MSGET oGetFatur VAR (U0J->U0J_PREFIX + "-" + U0J->U0J_NUM + "-" + U0J->U0J_PARCEL) SIZE 090, 010 OF oDlgLog COLORS 0, 16777215 PIXEL READONLY

    @ 150, 110 SAY oSay3 PROMPT "Filial" SIZE 025, 007 OF oDlgLog COLORS 0, 16777215 PIXEL
    @ 158, 110 MSGET oGetFil VAR U0J->U0J_FILIAL SIZE 050, 010 OF oDlgLog COLORS 0, 16777215 PIXEL READONLY

    @ 150, 165 SAY oSay3 PROMPT "Data e Hora" SIZE 025, 007 OF oDlgLog COLORS 0, 16777215 PIXEL
    @ 158, 165 MSGET oGetData VAR (DToC(U0J->U0J_DATA) + " " + U0J->U0J_HORA) SIZE 070, 010 OF oDlgLog COLORS 0, 16777215 PIXEL READONLY

    @ 171, 015 SAY oSay4 PROMPT "Processo" SIZE 025, 007 OF oDlgLog COLORS 0, 16777215 PIXEL
    @ 179, 015 MSGET oGetProcess VAR (iif(empty(U0J->U0J_PROCES),"Exclusão de Fatura",aDsTipo[Val(U0J->U0J_PROCES)])) SIZE 090, 010 OF oDlgLog COLORS 0, 16777215 PIXEL READONLY

    @ 171, 110 SAY oSay3 PROMPT "Usuário" SIZE 025, 007 OF oDlgLog COLORS 0, 16777215 PIXEL
    @ 179, 110 MSGET oGetUser VAR U0J->U0J_USER SIZE 125, 010 OF oDlgLog COLORS 0, 16777215 PIXEL READONLY
    
    @ 192, 015 SAY oSay5 PROMPT "Motivo" SIZE 025, 007 OF oDlgLog COLORS 0, 16777215 PIXEL
    @ 200, 015 MSGET oGetMovtivo VAR (U0J->U0J_MOTIVO + " " + Posicione("SX5",1,xFilial("SX5")+cTabSX5Mot+U0J->U0J_MOTIVO,"X5_DESCRI")) SIZE 220, 010 OF oDlgLog COLORS 0, 16777215 PIXEL READONLY

    @ 213, 015 SAY oSay6 PROMPT "Observações" SIZE 036, 007 OF oDlgLog COLORS 0, 16777215 PIXEL
    @ 221, 015 MSGET oGetObs VAR U0J->U0J_OBS SIZE 220, 010 OF oDlgLog COLORS 0, 16777215 PIXEL READONLY

    @ 234, 015 SAY oSay7 PROMPT "Detalhes Extras" SIZE 054, 007 OF oDlgLog COLORS 0, 16777215 PIXEL
    @ 242, 015 GET oGetDetail VAR U0J->U0J_DETAIL OF oDlgLog MULTILINE SIZE 220, 035 COLORS 0, 16777215 HSCROLL PIXEL READONLY
    
    @ 285, 204 BUTTON oBut1LF PROMPT "Fechar" SIZE 037, 012 OF oDlgLog PIXEL ACTION oDlgLog:end()

    ACTIVATE MSDIALOG oDlgLog CENTERED

Return
