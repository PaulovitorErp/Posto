#include "protheus.ch"
#include "topconn.ch"

/*/{Protheus.doc} TRETA043
Rotina Troca de Cliente nos Títulos.

@author Maiki Perin
@since 13/05/2015
@version 1.0

@param cFil, characters, filial
@param dEmissao, date, data de emissao
@param cCf, characters, cupom fiscal
@param cCliente, characters, cliente
@param cLojaCli, characters, loja
@param nRecno, numeric, recno da SE1
@param aRecnos, array,

@type function
/*/
User Function TRETA043(cFil,dEmissao,cCf,cCliente,cLojaCli,nRecno,aRecnos,_lAdmFin)

    Local cTitulo 		:= "Troca de Cliente nos Títulos"
    Local aButtons 		:= {}
    Local nX
    Local dBkDtBase 	:= dDataBase
    Local cBkpCCad      := iif(type("cCadastro")=="C", cCadastro, "")

    Default cFil := ""
    Default dEmissao := STOD("")
    Default cCf := ""
    Default cCliente := ""
    Default cLojaCli := ""
    Default nRecno := 0
    Default aRecnos := {}
    Default _lAdmFin := .F.

    Private oSay1, oSay2, oSay3

    Private aParam := Array(14)

    Private oGet1
    Private nCont 		:= 0
    Private nAux		:= 0
    Private cMarkAux    := "LBOK"
    //TODO: adicionar campo E1_ADM no grid
    Private aHead043    := {"OK","LEG","E1_FILIAL","E1_TIPO","X5_DESCRI","E1_PREFIXO","E1_NUM","E1_PARCELA","E1_VALOR","E1_SALDO","E1_EMISSAO","E1_CLIENTE","E1_LOJA",;
                            "E1_NOMCLI","CODCLI","LOJACLI","NOMECLI","MOTIVO","DESCMOTIVO","E1_ADM","AE_TAXA","E1_CARTAUT","E1_NSUTEF","E1_FILORIG"}
    Private aColEmp043   
    
    Private n43PosMark := aScan(aHead043, "OK")
    Private n43PosLeg := aScan(aHead043, "LEG")
    Private n43PosFil := aScan(aHead043, "E1_FILIAL")
    Private n43PosPfx := aScan(aHead043, "E1_PREFIXO")
    Private n43PosNum := aScan(aHead043, "E1_NUM")
    Private n43PosParc := aScan(aHead043, "E1_PARCELA")
    Private n43PosTipo := aScan(aHead043, "E1_TIPO")
    Private n43PosCli := aScan(aHead043, "E1_CLIENTE")
    Private n43PosLoja := aScan(aHead043, "E1_LOJA")
    Private n43PosVlr := aScan(aHead043, "E1_VALOR")
    Private n43PosSald := aScan(aHead043, "E1_SALDO")
    Private n43PosCDes := aScan(aHead043, "CODCLI")
    Private n43PosLDes := aScan(aHead043, "LOJACLI")
    Private n43PosNDes := aScan(aHead043, "NOMECLI")
    Private n43PosMoti := aScan(aHead043, "MOTIVO")
    Private n43PosDMot := aScan(aHead043, "DESCMOTIVO")
    Private n43PosTaxa := aScan(aHead043, "AE_TAXA")
    Private n43PosCAut := aScan(aHead043, "E1_CARTAUT")
    Private n43PosNSU := aScan(aHead043, "E1_NSUTEF")
    Private n43PosADM := aScan(aHead043, "E1_ADM")
    Private n43PosFOr := aScan(aHead043, "E1_FILORIG")

    Private _nRecno		:= nRecno
    Private _aRecnos 	:= aRecnos
    Private lAdmFin	:= _lAdmFin
    Private oSayObs 

    cCadastro := cTitulo

    Static oDlg

    If !empty(cFil+cCf+cCliente)

        aParam[01] := cFil
        aParam[02] := cFil
        aParam[03] := dEmissao
        aParam[04] := dEmissao
        aParam[05] := cCf
        aParam[06] := cCf
        aParam[07] := ""
        aParam[08] := cCliente
        aParam[09] := cCliente
        aParam[10] := cLojaCli
        aParam[11] := cLojaCli
        aParam[12] := 0
        aParam[13] := 0
        aParam[14] := ""

    ElseIf _nRecno > 0

        SE1->(DbGoTo(_nRecno))

        If SE1->(Eof())
            MsgInfo("Parâmetro <RECNO> inválido!!","Atenção")
            Return
        Endif

    elseif !empty(_aRecnos)

        for nX := 1 to len(_aRecnos)

            SE1->(DbGoTo(_aRecnos[nX]))

            If SE1->(Eof())
                MsgInfo("Parâmetro <RECNO> inválido!!","Atenção")
                Return
            Endif

        next nX

    Else

        If !ValidPerg()
            Return
        Endif
        
    Endif

    aObjects := {}
    aSizeAut := MsAdvSize()

    //Largura, Altura, Modifica largura, Modifica altura
    aAdd( aObjects, { 100,	90, .T., .T. } ) //Browse
    aAdd( aObjects, { 100,	10,	 .T., .T. } ) //Rodapé

    aInfo 	:= { aSizeAut[ 1 ], aSizeAut[ 2 ], aSizeAut[ 3 ], aSizeAut[ 4 ], 2, 2 }
    aPosObj := MsObjSize( aInfo, aObjects, .T. )

    DEFINE MSDIALOG oDlg TITLE cTitulo From aSizeAut[7],0 TO aSizeAut[6],aSizeAut[5] OF oMainWnd PIXEL

    //Browse
    oGet1 := GetDados1()
    oGet1:oBrowse:bHeaderClick := {|oBrw,nCol| IIF(nCol == 1,(CliqueT(),oBrw:SetFocus()),)}
    bSvblDblClick := oGet1:oBrowse:bLDblClick
    //oGet1:oBrowse:bLDblClick := {|| IIF(oGet1:oBrowse:nColPos <> 1,GdRstDblClick(@oGet1,@bSvblDblClick),Clique())}
    oGet1:oBrowse:bLDblClick := {|| Clique() }

    //Contador
    @ aPosObj[2,1], aPosObj[2,2] SAY oSay1 PROMPT "Registros selecionados:" SIZE 80, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ aPosObj[2,1], aPosObj[2,2]+80 SAY oSay2 PROMPT cValToChar(nCont) SIZE 40, 007 OF oDlg COLORS 0, 16777215 PIXEL

    @ aPosObj[2,1], aPosObj[2,2] + 130 BITMAP oBmp1 ResName "BR_VERDE" OF oDlg Size 10,10 NoBorder PIXEL
	@ aPosObj[2,1], aPosObj[2,2] + 145 SAY oSay3 PROMPT "Titulo em aberto" SIZE 080, 007 OF oDlg COLORS 0, 16777215 PIXEL

    @ aPosObj[2,1], aPosObj[2,2] + 195 BITMAP oBmp1 ResName "BR_Vermelho" OF oDlg Size 10,10 NoBorder PIXEL
	@ aPosObj[2,1], aPosObj[2,2] + 210 SAY oSay4 PROMPT "Titulo Baixado (total ou parcial)" SIZE 150, 007 OF oDlg COLORS 0, 16777215 PIXEL

    TButton():New( aPosObj[2,1], aPosObj[2,4]-85, "Selecionar Cliente", oDlg, {|| SelCli() }, 80, 12,,,.F.,.T.,.F.,,.F.,,,.F. )

    //Linha horizontal
    @ aPosObj[2,1] + 10, aPosObj[2,2] SAY oSay3 PROMPT Repl("_",aPosObj[1,4]) SIZE aPosObj[1,4], 007 OF oDlg COLORS CLR_GRAY, 16777215 PIXEL

    @ aPosObj[2,1] + 18, aPosObj[2,2] SAY oSayObs PROMPT "Obs: Foram selecionados também titulos de cartão da mesma tansação." SIZE 200, 007 OF oDlg COLORS 0, 16777215 PIXEL
    oSayObs:hide()

    MsgRun("Selecionando registros...","Aguarde",{|| BuscaDados()})

    aAdd(aButtons,{"Troca",{|| SelCli()},"Selecionar cliente","Selecionar cliente"})

    ACTIVATE MSDIALOG oDlg ON INIT (EnchoiceBar(oDlg, {|| Processa({|| ConfAlt()},"Realizando alterações...")}, {||oDlg:End()},,aButtons)   , iif(lAdmFin,SelCli(),)  )

    dDataBase := dBkDtBase
    cCadastro := cBkpCCad
Return

//------------------------------------
//monta grid tela
//------------------------------------
Static Function GetDados1()

    Local nX
    Local aHeaderEx 	:= {}
    Local aColsEx 		:= {}
    Local aFieldFill 	:= {}
    Local aFields 		:= aClone(aHead043)
    Local aAlterFields 	:= {}

    For nX := 1 to Len(aFields)
        If aFields[nX] == "OK" //Checkbox
            Aadd(aHeaderEx, {"","OK","@BMP",2,0,"","€€€€€€€€€€€€€€","C","","","",""})
            Aadd(aFieldFill, "LBNO")
        ElseIf aFields[nX] == "LEG" //legenda
            Aadd(aHeaderEx, {"","LEG","@BMP",2,0,"","€€€€€€€€€€€€€€","C","","","",""})
            Aadd(aFieldFill, "BR_BRANCO")
        ElseIf aFields[nX] == "CODCLI"
            Aadd(aHeaderEx, {"Cliente (novo)","COD","@!",TamSx3("A1_COD")[1],,"","€€€€€€€€€€€€€€","C","","","",""})
            Aadd(aFieldFill, Space(TamSx3("A1_COD")[1]))
        ElseIf aFields[nX] == "LOJACLI"
            Aadd(aHeaderEx, {"Loja","LOJA","@!",TamSx3("A1_LOJA")[1],,"","€€€€€€€€€€€€€€","C","","","",""})
            Aadd(aFieldFill, Space(TamSx3("A1_LOJA")[1]))
        ElseIf aFields[nX] == "NOMECLI"
            Aadd(aHeaderEx, {"Nome","NOME","@!",TamSx3("A1_NOME")[1],,"","€€€€€€€€€€€€€€","C","","","",""})
            Aadd(aFieldFill, Space(TamSx3("A1_NOME")[1]))
        ElseIf aFields[nX] == "MOTIVO"
            Aadd(aHeaderEx, {"Motivo","MOTIVO","@!",2,,"","€€€€€€€€€€€€€€","C","","","",""})
            Aadd(aFieldFill, Space(2))
        ElseIf aFields[nX] == "DESCMOTIVO"
            Aadd(aHeaderEx, {"Descrição","DESCMOTIVO","@!",55,,"","€€€€€€€€€€€€€€","C","","","",""})
            Aadd(aFieldFill, Space(55))
        else
            Aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
            If aFields[nX] == "X5_DESCRI"
                aHeaderEx[len(aHeaderEx)][1] := "Descrição"
            ElseIf aFields[nX] == "E1_CLIENTE"
                aHeaderEx[len(aHeaderEx)][1] := "Cliente (atual)"
            elseif aFields[nX] == "AE_TAXA"
                aHeaderEx[len(aHeaderEx)][1] := "Nova Taxa Adm."
            Endif
            aAdd(aFieldFill, CriaVar(aFields[nX]))
        Endif
    Next

    aAdd(aFieldFill, .F.)
    aAdd(aColsEx, aFieldFill)

    aColEmp043 := aClone(aFieldFill)

Return MsNewGetDados():New(aPosObj[1,1],aPosObj[1,2],aPosObj[1,3],aPosObj[1,4],,"AllwaysTrue","AllwaysTrue",,aAlterFields,,999,;
		"AllwaysTrue","","AllwaysTrue",oDlg,aHeaderEx,aColsEx)

//------------------------------------------------------------------
// busca dados para apresentação na tela
//------------------------------------------------------------------
Static Function BuscaDados()

    Local nX
    Local cQry 		:= ""
    Local cTpTit	:= ""
    Local aChvCCParc := {}
    Local lMsgCCParc := .F.
    Local lBaixado := .F.

    //Zera o contador
    nCont := 0

    //Limpa o aCols
    aSize(oGet1:aCols,0)

    If Select("QRYTIT") > 0
        QRYTIT->(DbCloseArea())
    Endif

    cQry := "SELECT SE1.E1_FILIAL, SE1.E1_TIPO, SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA, SE1.E1_VALOR, SE1.E1_VLRREAL, SE1.E1_EMISSAO, SE1.E1_CLIENTE,"
    cQry += " SE1.E1_LOJA, SE1.E1_NOMCLI, E1_CARTAUT, E1_NSUTEF, E1_SALDO, E1_ADM, E1_FILORIG"

    If _nRecno > 0 .OR. !empty(_aRecnos)
        if len(cFilAnt) <> len(AlltriM(xFilial("SE1")))
            cQry += " FROM "+RetSqlName("SE1")+" SE1 LEFT JOIN "+RetSqlName("SF2")+" SF2 ON		SF2.F2_FILIAL	= SE1.E1_FILORIG"
        else
            cQry += " FROM "+RetSqlName("SE1")+" SE1 LEFT JOIN "+RetSqlName("SF2")+" SF2 ON		SF2.F2_FILIAL	= '"+cFilAnt+"'"
        endif
    Else
        cQry += " FROM "+RetSqlName("SE1")+" SE1 LEFT JOIN "+RetSqlName("SF2")+" SF2 ON		SF2.F2_FILIAL		BETWEEN '"+aParam[01]+"' AND '"+aParam[02]+"'"
    Endif
    cQry += " 																			AND SE1.E1_NUM		= SF2.F2_DOC"
    cQry += " 																			AND SE1.E1_PREFIXO	= SF2.F2_SERIE"
    cQry += " 																			AND SF2.F2_NFCUPOM	= ''" //Não possui NF s/Cupom
    cQry += " 																			AND SF2.D_E_L_E_T_ 	<> '*'"
    cQry += " WHERE SE1.D_E_L_E_T_ 	<> '*'"

    If _nRecno > 0
        cQry += " AND SE1.R_E_C_N_O_ = '"+alltrim(str(_nRecno))+"'"
    elseif !empty(_aRecnos)
        _cRecQry := alltrim(str(_aRecnos[1]))
        For nX := 2 to len(_aRecnos)
            _cRecQry += ","+alltrim(str(_aRecnos[nX]))
        next nX
        cQry += " AND SE1.R_E_C_N_O_ IN ("+_cRecQry+")"
    Else
        if len(cFilAnt) <> len(AlltriM(xFilial("SE1")))
            cQry += " AND SE1.E1_FILORIG	BETWEEN '"+aParam[01]+"' AND '"+aParam[02]+"'"
        else
            cQry += " AND SE1.E1_FILIAL		BETWEEN '"+aParam[01]+"' AND '"+aParam[02]+"'"
        endif
        cQry += " AND SE1.E1_EMISSAO	BETWEEN '"+DToS(aParam[03])+"' AND '"+DToS(aParam[04])+"'"
        cQry += " AND SE1.E1_NUM		BETWEEN '"+aParam[05]+"' AND '"+aParam[06]+"'"

        If !Empty(aParam[07]) .AND. SE1->(FieldPos("E1_XPLACA"))>0
            cQry += " AND SE1.E1_XPLACA		= '"+aParam[07]+"'"
        Endif

        cQry += " AND SE1.E1_CLIENTE	BETWEEN '"+aParam[08]+"' AND '"+aParam[09]+"'"
        cQry += " AND SE1.E1_LOJA		BETWEEN '"+aParam[10]+"' AND '"+aParam[11]+"'"

        If !Empty(aParam[12]) .And. !Empty(aParam[13])
            cQry += " AND SE1.E1_VALOR		BETWEEN '"+cValToChar(aParam[12])+"' AND '"+cValToChar(aParam[13])+"'"

        ElseIf !Empty(aParam[12])
            cQry += " AND SE1.E1_VALOR		>= '"+cValToChar(aParam[12])+"'"

        ElseIf !Empty(aParam[13])
            cQry += " AND SE1.E1_VALOR		<= '"+cValToChar(aParam[13])+"'"
        Endif

        If !Empty(aParam[14])
            cQry += " AND SE1.E1_TIPO		= '"+aParam[14]+"'"
        Endif
    Endif
    
    cQry += " AND SE1.E1_TIPO <> 'FT'" //Não pode alterar de Fatura
    cQry += " ORDER BY SE1.E1_FILIAL, SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA, SE1.E1_TIPO"

    cQry := ChangeQuery(cQry)
    //MemoWrite("c:\temp\TRETE043.txt",cQry)
    TcQuery cQry NEW Alias "QRYTIT"

    If QRYTIT->(!EOF())

        While QRYTIT->(!EOF())
            
            cTpTit := Posicione("SX5",1,xFilial("SX5")+"05"+QRYTIT->E1_TIPO,"X5_DESCRI")
            lBaixado := Round(QRYTIT->E1_SALDO,2) <> Round(QRYTIT->E1_VALOR,2)

            //{"OK","LEG","E1_FILIAL","E1_TIPO","X5_DESCRI","E1_PREFIXO","E1_NUM","E1_PARCELA","E1_VALOR","E1_SALDO","E1_EMISSAO","E1_CLIENTE","E1_LOJA",;
            // "E1_NOMCLI","CODCLI","LOJACLI","NOMECLI","MOTIVO","DESCMOTIVO","E1_ADM","AE_TAXA","E1_CARTAUT","E1_NSUTEF"}
            aAdd(oGet1:aCols,{iif(lAdmFin .AND. !lBaixado,"LBOK","LBNO"),;					
                                iif(lBaixado, "BR_VERMELHO","BR_VERDE") ,;
                                QRYTIT->E1_FILIAL,;		
                                QRYTIT->E1_TIPO,;		
                                AllTrim(cTpTit),;		
                                QRYTIT->E1_PREFIXO,;	
                                QRYTIT->E1_NUM,;		
                                QRYTIT->E1_PARCELA,;	
                                IIF(QRYTIT->E1_VLRREAL > 0 .And. QRYTIT->E1_VLRREAL <> QRYTIT->E1_VALOR,QRYTIT->E1_VLRREAL,QRYTIT->E1_VALOR),;	//8
                                QRYTIT->E1_SALDO,;	
                                DToC(SToD(QRYTIT->E1_EMISSAO)),;	
                                QRYTIT->E1_CLIENTE,;	
                                QRYTIT->E1_LOJA,;		
                                QRYTIT->E1_NOMCLI,;		
                                Space(6),;				
                                Space(2),;				
                                Space(40),;				
                                Space(2),;				
                                Space(55),;				
                                Space(3),;				
                                0,;						
                                QRYTIT->E1_CARTAUT ,;
                                QRYTIT->E1_NSUTEF ,;
                                QRYTIT->E1_FILORIG ,;
                                .F.})

            if (lAdmFin .AND. !lBaixado)
                nCont++
            endif

            //guardo chave para verificar outras parcelas de cartao da mesma transacao
            if Alltrim(SE1->E1_TIPO) == "CC"
                if aScan(aChvCCParc, {|x| x[1]+x[2]+x[3]+x[4]+x[5]+x[6]+x[7]+x[8] == QRYTIT->E1_FILIAL+QRYTIT->E1_PREFIXO+QRYTIT->E1_NUM+QRYTIT->E1_CLIENTE+QRYTIT->E1_LOJA+QRYTIT->E1_CARTAUT+QRYTIT->E1_NSUTEF+QRYTIT->E1_FILORIG }) == 0
                    aadd(aChvCCParc, {QRYTIT->E1_FILIAL, QRYTIT->E1_PREFIXO, QRYTIT->E1_NUM, QRYTIT->E1_CLIENTE, QRYTIT->E1_LOJA, QRYTIT->E1_CARTAUT, QRYTIT->E1_NSUTEF, QRYTIT->E1_FILORIG} )
                endif
            endif

            QRYTIT->(dbSkip())
        EndDo

        If Select("QRYPARC") > 0
            QRYPARC->(DbCloseArea())
        Endif
        //verifico se há outras parcelas da mesma transação de cartão para adicionar junto
        for nX := 1 to len(aChvCCParc)
            
            cQry := "SELECT SE1.E1_FILIAL, SE1.E1_TIPO, SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA, SE1.E1_VALOR, SE1.E1_VLRREAL, SE1.E1_EMISSAO, SE1.E1_CLIENTE,"
            cQry += " SE1.E1_LOJA, SE1.E1_NOMCLI, E1_CARTAUT, E1_NSUTEF, E1_SALDO, E1_ADM, E1_FILORIG"
            cQry += " FROM "+RetSqlName("SE1")+" SE1 "
            cQry += " WHERE SE1.D_E_L_E_T_ 	<> '*'"
            cQry += " AND SE1.E1_FILIAL	 = '"+aChvCCParc[nX][1]+"'"
            cQry += " AND SE1.E1_PREFIXO = '"+aChvCCParc[nX][2]+"'"
            cQry += " AND SE1.E1_NUM	 = '"+aChvCCParc[nX][3]+"'"
            cQry += " AND SE1.E1_CLIENTE = '"+aChvCCParc[nX][4]+"'"
            cQry += " AND SE1.E1_LOJA	 = '"+aChvCCParc[nX][5]+"'"
            cQry += " AND SE1.E1_CARTAUT = '"+aChvCCParc[nX][6]+"'"
            cQry += " AND SE1.E1_NSUTEF	 = '"+aChvCCParc[nX][7]+"'"
            if len(cFilAnt) <> len(AlltriM(xFilial("SE1")))
                cQry += " AND SE1.E1_FILORIG = '"+aChvCCParc[nX][8]+"'"
            endif
            cQry += " AND SE1.E1_TIPO = 'CC'" 
            cQry += " ORDER BY SE1.E1_FILIAL, SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA, SE1.E1_TIPO"

            cQry := ChangeQuery(cQry)
            //MemoWrite("c:\temp\TRETE043.txt",cQry)
            TcQuery cQry NEW Alias "QRYPARC"
            
            While QRYPARC->(!EOF())
                
                if aScan(oGet1:aCols, {|x| x[n43PosFil]+x[n43PosPfx]+x[n43PosNum]+x[n43PosParc]+x[n43PosTipo]+x[n43PosCli]+x[n43PosLoja] == QRYPARC->E1_FILIAL+QRYPARC->E1_PREFIXO+QRYPARC->E1_NUM+QRYPARC->E1_PARCELA+QRYPARC->E1_TIPO+QRYPARC->E1_CLIENTE+QRYPARC->E1_LOJA }) == 0
                    lMsgCCParc := .T.
                    lBaixado := Round(QRYPARC->E1_SALDO,2) <> Round(QRYPARC->E1_VALOR,2)

                    aAdd(oGet1:aCols,{iif(lAdmFin .AND. !lBaixado,"LBOK","LBNO"),;
                        iif(lBaixado, "BR_VERMELHO","BR_VERDE") ,;
                        QRYPARC->E1_FILIAL,;	
                        QRYPARC->E1_TIPO,;		
                        AllTrim(cTpTit),;		
                        QRYPARC->E1_PREFIXO,;	
                        QRYPARC->E1_NUM,;		
                        QRYPARC->E1_PARCELA,;	
                        IIF(QRYPARC->E1_VLRREAL > 0 .And. QRYPARC->E1_VLRREAL <> QRYPARC->E1_VALOR,QRYPARC->E1_VLRREAL,QRYPARC->E1_VALOR),;	//8
                        QRYPARC->E1_SALDO,;
                        DToC(SToD(QRYPARC->E1_EMISSAO)),;	
                        QRYPARC->E1_CLIENTE,;	
                        QRYPARC->E1_LOJA,;		
                        QRYPARC->E1_NOMCLI,;	
                        Space(6),;				
                        Space(2),;				
                        Space(40),;				
                        Space(2),;				
                        Space(55),;				
                        Space(3),;				
                        0,;						
                        QRYPARC->E1_CARTAUT ,;
                        QRYPARC->E1_NSUTEF ,;
                        QRYPARC->E1_FILORIG ,;
                        .F.})

                    if (lAdmFin .AND. !lBaixado)
                        nCont++
                    endif					

                endif
                
                QRYPARC->(dbSkip())
            EndDo

            QRYPARC->(DbCloseArea())
        next nX

    Else
        MsgInfo("Nenhum registro selecionado !!","Atenção")
        aAdd(oGet1:aCols, aClone(aColEmp043) )
    Endif

    QRYTIT->(DbCloseArea())

    if lMsgCCParc
        MsgInfo("Há titulos de cartão parcelado! Foi adicionado na lista todos os titulos de parcelas da mesma transação de cartão.","Troca de Sacado")
        ASORT(oGet1:aCols,,, { |x, y| x[n43PosFil]+x[n43PosPfx]+x[n43PosNum]+x[n43PosParc]+x[n43PosTipo] < y[n43PosFil]+y[n43PosPfx]+y[n43PosNum]+y[n43PosParc]+y[n43PosTipo] } ) //ordem crescente
    endif

    oGet1:Refresh()
    oSay2:Refresh()

Return

//-----------------------------------------------
// duplo clique do browse
//-----------------------------------------------
Static Function Clique()

    Local nI
    Local lOK := .T.
    
    oSayObs:hide()

    If oGet1:aCols[oGet1:nAt][n43PosMark] == "LBOK"
        oGet1:aCols[oGet1:nAt][n43PosMark] := "LBNO"
        nCont--
    Elseif oGet1:aCols[oGet1:nAt][n43PosLeg] == "BR_VERDE"
        oGet1:aCols[oGet1:nAt][n43PosMark] := "LBOK"
        nCont++
    else
        MsgAlert("Titulo com baixa! Não será possível alteração do cliente.")
        lOK := .F.
    Endif

    //se cartao, verifico titulos parcelas, para marcar ou desmacar junto
    if lOK .AND. Alltrim(oGet1:aCols[oGet1:nAt][n43PosTipo]) == "CC" 
        for nI := 1 to len(oGet1:aCols)
            if nI <> oGet1:nAt 
                if oGet1:aCols[nI][n43PosFil]+oGet1:aCols[nI][n43PosCli]+oGet1:aCols[nI][n43PosLoja]+oGet1:aCols[nI][n43PosPfx]+oGet1:aCols[nI][n43PosNum]+oGet1:aCols[nI][n43PosTipo]+oGet1:aCols[nI][n43PosCAut]+oGet1:aCols[nI][n43PosNSU]+oGet1:aCols[nI][n43PosfOr] == ;
                    oGet1:aCols[oGet1:nAt][n43PosFil]+oGet1:aCols[oGet1:nAt][n43PosCli]+oGet1:aCols[oGet1:nAt][n43PosLoja]+oGet1:aCols[oGet1:nAt][n43PosPfx]+oGet1:aCols[oGet1:nAt][n43PosNum]+oGet1:aCols[oGet1:nAt][n43PosTipo]+oGet1:aCols[oGet1:nAt][n43PosCAut]+oGet1:aCols[oGet1:nAt][n43PosNSU]+oGet1:aCols[oGet1:nAt][n43PosFOr]

                    if oGet1:aCols[nI][n43PosLeg] == "BR_VERDE"
                        oGet1:aCols[nI][n43PosMark] := oGet1:aCols[oGet1:nAt][n43PosMark]
                        if oGet1:aCols[nI][n43PosMark] == "LBOK"
                            nCont++
                            oSayObs:show()
                        else
                            nCont--
                        endif
                    endif
                endif
            endif
        next nI
    endif

    oGet1:oBrowse:Refresh()
    oSay2:Refresh()

Return

//-----------------------------------------------
// selciona todos itens
//-----------------------------------------------
Static Function CliqueT()
    Local nI

    If nAux == 1
        nAux := 0
    Else
        nCont := 0

        If cMarkAux == "LBOK"
            For nI := 1 To Len(oGet1:aCols)
                oGet1:aCols[nI][n43PosMark] := "LBNO"
            Next
            nCont := 0
            cMarkAux := "LBNO"
        Else
            For nI := 1 To Len(oGet1:aCols)
                if oGet1:aCols[nI][n43PosLeg] == "BR_VERDE"
                    oGet1:aCols[nI][n43PosMark] := "LBOK"
                    nCont++
                endif
            Next
            cMarkAux := "LBOK"
        Endif

        nAux := 1
    Endif

    oGet1:oBrowse:Refresh()
    oSay2:Refresh()

Return

//-----------------------------------------------
// Confirma Alteracao
//-----------------------------------------------
Static Function ConfAlt()

Local nI, nZ
Local aRecSE1Alt 	:= {}
Local aFin040 		:= {}
Local nX 			:= 0
Local _nVlrLiq 		:= 0
Local lContinua 	:= .T.


/*********************************************************/
/**** VARIAVEIS CONTABILIZACAO DE TROCA DE SACADO ********/
/*********************************************************/
Local dMVDtMax		:= SuperGetMV("MV_XDTMAX",,Stod("20010101"))	 // Parametro com a Data Maxima retroativa para troca de sacado - Sampaio 11/07/2016
Local cMVTipSac		:= SuperGetMV("MV_XTIPSAC",,"R$,CC,CD,NP,CF")// Parametro com os tipos de titulo que permitem troca de sacado - Sampaio 28/07/2016
Local dDtSalva		:= StoD("")						 // Variavel para salvar a dDataBase do Sistema - Sampaio 11/07/2016
Local lCtbFat		:= .F. 							 // Variavel logica de contabilizacao do faturamento - Sampaio 11/07/2016
Local lCtbFin		:= .F. 							 // Variavel logica de contabilizacao do financeiro - Sampaio 11/07/2016
Local lHeader      	:= .F. 							 // Variavel logica de contabilizacao - Sampaio 11/07/2016
Local nHdlPrv		:= 0                             // Variavel para a contabilizacao - Sampaio 11/07/2016
Local cArquivo		:= "" 							 // Variavel de arquivo para contabilizacao - Sampaio 11/07/2016
Local nTotalCtb		:= 0
Local dDtCTB        := StoD("")

Local aAreaSF2		:= SF2->(GetArea()) 			 // GMdS | Guarda Area da SF2
Local aAreaSL1		:= SL1->(GetArea()) 			 // GMdS | Guarda Area da SL1

Local aDadosBx		:= {}
Local aFin070		:= {}
Local aBaixa		:= {}
Local cBkpFunNam := FunName()
Local lMVVFilOri	:= len(cFilAnt) <> len(AlltriM(xFilial("SE1"))) //SuperGetMV("MV_XFILORI", .F., .F.)
Local cBkpOrigem := ""

Private cCliAnt		:= ""
Private cLojAnt		:= ""
/*********************************************************/

dbSelectArea("SE1")
SE1->(dbSetOrder(2)) //E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
For nI := 1 To Len(oGet1:aCols)

	If oGet1:aCols[nI][n43PosMark] == "LBOK" .And. !Empty(oGet1:aCols[nI][n43PosCDes])

	 	//Verifica contabilização no Financeiro - SE1
		If SE1->(dbSeek(oGet1:aCols[nI][n43PosFil]+oGet1:aCols[nI][n43PosCli]+oGet1:aCols[nI][n43PosLoja]+oGet1:aCols[nI][n43PosPfx]+oGet1:aCols[nI][n43PosNum]+oGet1:aCols[nI][n43PosParc]+oGet1:aCols[nI][n43PosTipo]))

			While SE1->(!EOF()) .And. SE1->(E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO) == oGet1:aCols[nI][n43PosFil]+oGet1:aCols[nI][n43PosCli]+oGet1:aCols[nI][n43PosLoja]+oGet1:aCols[nI][n43PosPfx]+oGet1:aCols[nI][n43PosNum]+oGet1:aCols[nI][n43PosParc]+oGet1:aCols[nI][n43PosTipo]

                    // Verifica se é diferente dos tipos no MV_XTIPSAC - Sampai0 28/07/2016
                    if !(AllTrim(SE1->E1_TIPO) $ cMVTipSac )
                        MsgAlert("O Tipo do Título <"+AllTrim(SE1->E1_NUM)+"/"+AllTrim(SE1->E1_PREFIXO)+"> não pode ser alterado.")
						lContinua := .F.
						Exit
                    endif

					// Verifico se o titulo esta baixado - Sampaio 11/07/2016
					If SE1->E1_SALDO <> SE1->E1_VALOR

						MsgAlert("O Título <"+AllTrim(SE1->E1_NUM)+"/"+AllTrim(SE1->E1_PREFIXO)+"> no Financeiro já está baixado total ou parcialmente. A operação de Troca não será permitida.")
						lContinua := .F.
						Exit

					EndIf

                    // Nova validacao, verifico se o E1_LA está diferente de vazio,
					// se o conteudo for igual a "S" e a emissao for menor/igual que o parametro MV_XDTMAX
					If !Empty(SE1->E1_LA) .And. AllTrim(SE1->E1_LA) == "S" 

                        if SE1->E1_EMISSAO <= dMVDtMax
                            MsgInfo("O Título <"+AllTrim(SE1->E1_NUM)+"/"+AllTrim(SE1->E1_PREFIXO)+"> se encontra contabilizado";
                            + " quanto ao Financerio (E1_LA), operação de troca não permitida para data retroativa a "+DtoC(dMVDtMax)+". Favor verificar com o depto. contábil ";
                            + "o estorno desta contabilização.","Atenção")
                            lContinua := .F.
                            Exit
                        endif
                        
                        //validaçao para alteração da taxa adm financeira
                        //TODO: Alterar para verificar posicione a partir do E1_ADM
						if SE1->E1_SALDO == SE1->E1_VALOR .AND. !empty(Posicione("SAE",1,xFilial("SAE",iif(lMVVFilOri,oGet1:aCols[nI][n43PosFOr],oGet1:aCols[nI][n43PosFil]))+Alltrim(oGet1:aCols[nI][n43PosCDes]),"AE_COD")) //oGet1:aCols[nI][18] > 0 //se tit totalmente aberto e é de adm financeira
							_nVlrLiq := Round( iif(empty(SE1->E1_VLRREAL),SE1->E1_VALOR,SE1->E1_VLRREAL)*(1-(oGet1:aCols[nI][n43PosTaxa]/100)), TAMSX3("E1_VALOR")[2] )
							if _nVlrLiq <> SE1->E1_VALOR //se realmente precisa alterar valor
								MsgInfo("O Título <"+AllTrim(SE1->E1_NUM)+"/"+AllTrim(SE1->E1_PREFIXO)+"> se encontra contabilizado";
									+ " quanto ao Financerio (E1_LA), operação de troca sacado com alteração de taxa de administração não permitida. Favor verificar com o depto. contábil ";
									+ "o estorno desta contabilização para realizar essa operação.","Atenção")
								lContinua := .F.
								Exit
							endif
						endif
					Endif

					// posiciona na tabela de SE5
					SE5->(DbSetOrder(7))
                    SE5->(DbGoTop())
                    SE5->(DbSeek(xFilial('SE5')+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO+SE1->E1_CLIENTE+SE1->E1_LOJA))
					If SE1->E1_TIPO='R$' .And. !SE5->(EOF()) .And. !Empty(SE5->E5_LA) .And. AllTrim(SE5->E5_LA) == "S" .And. SE5->E5_DATA <= dMVDtMax

						MsgInfo("O Cupom Fiscal <"+AllTrim(SF2->F2_DOC)+"/"+AllTrim(SF2->F2_SERIE)+"> se encontra contabilizado";
						+ " quanto ao Financeiro (E5_LA), operação de troca não permitida para data retroativa a "+DtoC(dMVDtMax)+". Favor verificar com o depto. contábil ";
						+ "o estorno desta contabilização.","Atenção")
						lContinua := .F.
						Exit

					Endif

				SE1->(DbSkip())
			EndDo

			If !lContinua
				Exit
			Endif
		Endif
	Endif
Next

// GMdS | 04-04-2017 : Adicionada validação se existe NF Sobre Cupom
If lContinua
	aAreaSF2 := SF2->(GetArea()) // GMdS | Guarda Area da SF2
	aAreaSL1 := SL1->(GetArea()) // GMdS | Guarda Area da SL1

	For nI := 1 To Len(oGet1:aCols)

		If oGet1:aCols[nI][n43PosMark] == "LBOK" .And. !Empty(oGet1:aCols[nI][n43PosCDes]) .And. !(AllTrim(oGet1:aCols[nI][n43PosTipo]) $ cMVTipSac )

	    	DbSelectArea("SL1")
            SL1->(DbSetOrder(2))
	       	If SL1->( MsSeek(oGet1:aCols[nI][iif(lMVVFilOri,n43PosFOr,n43PosFil)]+oGet1:aCols[nI][n43PosPfx]+oGet1:aCols[nI][n43PosNum] ) )
				If oGet1:aCols[nI][n43PosCli]+oGet1:aCols[nI][n43PosLoja] == SL1->L1_CLIENTE + SL1->L1_LOJA
                    SF2->(DbSetOrder(2))                
					If SF2->(MsSeek( SL1->L1_FILIAL + SL1->L1_CLIENTE + SL1->L1_LOJA + SL1->L1_DOC + SL1->L1_SERIE ) )
						If !Empty(AllTrim(SF2->F2_NFCUPOM))
					   		MsgInfo("O Cupom Fiscal <"+AllTrim(SF2->F2_DOC)+"/"+AllTrim(SF2->F2_SERIE)+"> já contém NF Sobre Cupom.";
							+ " Troca de Sacado não é possível após a emissão da NF Sobre Cupom.", "Atenção" )
							lContinua := .F.
						EndIf
					EndIf
		        EndIf
		   	EndIf

		EndIf

	Next nI

	RestArea(aAreaSF2)
	RestAreA(aAreaSL1)
EndIf

If lContinua

	If MsgYesNo("Será realizada a troca de clientes nos títulos selecionados, deseja continuar ?")

		ProcRegua(Len(oGet1:aCols))

		// Inicia a transacao - Dt. 19/07/2016
		BEGIN TRANSACTION

		For nI := 1 To Len(oGet1:aCols)

			If oGet1:aCols[nI][n43PosMark] == "LBOK" .And. !Empty(oGet1:aCols[nI][iif(lMVVFilOri,n43PosFOr,n43PosFil)]) .And. !Empty(oGet1:aCols[nI][n43PosCDes])

				IncProc()
				nAux++
				aRecSE1Alt := {}

				//Altera SE1
				If SE1->(dbSeek(oGet1:aCols[nI][n43PosFil]+oGet1:aCols[nI][n43PosCli]+oGet1:aCols[nI][n43PosLoja]+oGet1:aCols[nI][n43PosPfx]+oGet1:aCols[nI][n43PosNum]+oGet1:aCols[nI][n43PosParc]+oGet1:aCols[nI][n43PosTipo]))

					While SE1->(!EOF()) .And.;
						SE1->(E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO) == oGet1:aCols[nI][n43PosFil]+oGet1:aCols[nI][n43PosCli]+oGet1:aCols[nI][n43PosLoja]+oGet1:aCols[nI][n43PosPfx]+oGet1:aCols[nI][n43PosNum]+oGet1:aCols[nI][n43PosParc]+oGet1:aCols[nI][n43PosTipo]

						AAdd(aRecSE1Alt, SE1->(Recno()) )

						SE1->(dbSkip())
					EndDo

					For nX := 1 to Len(aRecSE1Alt)

						cCliAnt		:= ""
						cLojAnt		:= ""

						SE1->(DbGoTo(aRecSE1Alt[nX]))

						//Abre a Contabilizacao - Sampaio 11/07/2016
						lContinua := U_TRETA044(2,1,@lHeader,/*@lCtbFat*/Nil,@lCtbFin,@nHdlPrv,@nTotalCtb,@cArquivo,@dDtSalva,@dDtCTB,@cCliAnt,@cLojAnt,FunName())
						If !lContinua
							Loop
						EndIf

						//Verifica baixa(s) do Título
						DbSelectArea("SE5")
						SE5->(DbSetOrder(7)) //E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA+E5_SEQ
						
						If SE5->(DbSeek(xFilial("SE5")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO+SE1->E1_CLIENTE+SE1->E1_LOJA))
							
							While SE5->(!EOF()) .And. SE5->E5_FILIAL == xFilial("SE5") .And. SE5->E5_PREFIXO == SE1->E1_PREFIXO .And.;
								SE5->E5_NUMERO == SE1->E1_NUM .And. SE5->E5_PARCELA == SE1->E1_PARCELA .And. SE5->E5_TIPO == SE1->E1_TIPO .And.;
								SE5->E5_CLIFOR == SE1->E1_CLIENTE .And. SE5->E5_LOJA == SE1->E1_LOJA

                                if SE5->E5_SITUACA != "C" .AND. !SE5->(TemBxCanc()) //se movimento nao cancelado

                                    //Guarda dados da baixa
                                    AAdd(aDadosBx,{SE5->E5_BANCO,SE5->E5_AGENCIA,SE5->E5_CONTA,SE5->E5_PREFIXO,SE5->E5_NUMERO,SE5->E5_PARCELA,SE5->E5_TIPO,;
                                                    SE5->E5_DATA,SE5->E5_VALOR,SE5->E5_HISTOR,SE5->E5_MOTBX,SE5->E5_TIPODOC,;
                                                    iif(SE5->(FieldPos("E5_XPDV"))>0,SE5->E5_XPDV,""), ;
                                                    iif(SE5->(FieldPos("E5_XESTAC"))>0,SE5->E5_XESTAC,""), ;
                                                    SE5->E5_NUMMOV,;
                                                    iif(SE5->(FieldPos("E5_XHORA"))>0,SE5->E5_XHORA,"") })
                                    
                                    //Exclui a Baixa
                                    lMsErroAuto := .F.
                                    aFin070 	:= {}
                                    
                                    AAdd(aFin070, {"E1_FILIAL"  , SE1->E1_FILIAL	, Nil})
                                    AAdd(aFin070, {"E1_PREFIXO" , SE1->E1_PREFIXO	, Nil})
                                    AAdd(aFin070, {"E1_NUM"     , SE1->E1_NUM		, Nil})
                                    AAdd(aFin070, {"E1_PARCELA" , SE1->E1_PARCELA 	, Nil})
                                    AAdd(aFin070, {"E1_TIPO"    , SE1->E1_TIPO		, Nil})

                                    MSExecAuto({|x,y| Fina070(x,y)}, aFin070, 6) //rotina automática para cancelamento da baixa;

                                    If lMsErroAuto
                                        MostraErro()
                                        DisarmTransaction()
                                        lContinua := .F.
                                        EXIT
                                    Endif

                                endif
								
								SE5->(DbSkip())
							EndDo
						Endif
						
						//Altera o sacado
                        if lContinua
                            RecLock("SE1",.F.)
                            SE1->E1_CLIENTE := oGet1:aCols[nI][n43PosCDes]
                            SE1->E1_LOJA	:= oGet1:aCols[nI][n43PosLDes]
                            SE1->E1_NOMCLI	:= Posicione("SA1",1,xFilial("SA1")+oGet1:aCols[nI][n43PosCDes]+oGet1:aCols[nI][n43PosLDes],"A1_NOME")
                            //TODO: tratar a alteração da ADM Financeira
                            SE1->(MsUnlock())
                        endif

						//Realiza baixa se houver
						If lContinua .AND. Len(aDadosBx) > 0

							For nZ := 1 To Len(aDadosBx)

								lMsErroAuto := .F.
								aBaixa 		:= {}
								
								aBaixa := {;
									{"E1_PREFIXO"   ,aDadosBx[nZ][4]		,Nil},;
									{"E1_NUM"       ,aDadosBx[nZ][5]		,Nil},;
									{"E1_PARCELA"   ,aDadosBx[nZ][6]		,Nil},;
									{"E1_TIPO"      ,aDadosBx[nZ][7]		,Nil},;
									{"E1_CLIENTE" 	,oGet1:aCols[nI][n43PosCDes]	,Nil},;
									{"E1_LOJA" 		,oGet1:aCols[nI][n43PosLDes]	,Nil},;
									{"AUTMOTBX"     ,aDadosBx[nZ][11]		,Nil},;
									{"AUTBANCO"     ,aDadosBx[nZ][1] 		,Nil},;
									{"AUTAGENCIA"   ,aDadosBx[nZ][2]		,Nil},;
									{"AUTCONTA"     ,aDadosBx[nZ][3]		,Nil},;
									{"AUTDTBAIXA"   ,aDadosBx[nZ][8]		,Nil},;
									{"AUTDTCREDITO" ,aDadosBx[nZ][8]		,Nil},;
									{"AUTHIST"      ,aDadosBx[nZ][10] 		,Nil},;
									{"AUTJUROS"     ,0      				,Nil},;
									{"AUTVALREC"    ,aDadosBx[nZ][9]		,Nil}}

                                SetFunName("FINA070") //ADD Danilo, para ficar correto campo E5_ORIGEM (relatorios e rotinas conciliacao)					
								MSExecAuto({|x,y| Fina070(x,y)}, aBaixa, 3) //Baixa conta a receber
                                SetFunName(cBkpFunNam)
	
								If lMsErroAuto
								    MostraErro()
									DisarmTransaction()
                                    lContinua := .F.
									EXIT
								Else
									RecLock("SE5",.F.)
									SE5->E5_TIPODOC	:= aDadosBx[nZ][12]
                                    if SE5->(FieldPos("E5_XPDV")) > 0
									    SE5->E5_XPDV 	:= aDadosBx[nZ][13]
                                    endif
                                    if SE5->(FieldPos("E5_XESTAC")) > 0
									    SE5->E5_XESTAC 	:= aDadosBx[nZ][14]
                                    endif
									SE5->E5_NUMMOV := aDadosBx[nZ][15]
                                    if SE5->(FieldPos("E5_XHORA")) > 0
									    SE5->E5_XHORA 	:= aDadosBx[nZ][16]
                                    endif
									SE5->(MsUnlock())
								Endif
							Next nZ
						Endif

						if !lContinua
                            EXIT
                        endif

						SE1->(DbGoTo(aRecSE1Alt[nX]))

						/**************************************************/
						/* Contabilizacao Financeiro - Sampaio 12/07/2016 *
						/**************************************************/
						U_TRETA044(2,2,lHeader,/*@lCtbFat*/Nil,lCtbFin,@nHdlPrv,@nTotalCtb,@cArquivo,@dDtSalva,Nil,@cCliAnt,@cLojAnt,FunName())

						/****************************************************/
						/*	Encerra a Contabilizacao - Sampaio 11/07/2016	*
						/****************************************************/
						U_TRETA044(3,Nil,lHeader,lCtbFat,lCtbFin,nHdlPrv,@nTotalCtb,cArquivo,@dDtSalva,Nil,@cCliAnt,@cLojAnt,FunName())

						//alteração da taxa adm financeira
                        //TODO tratar para buscar pelo campo E1_ADM
						if SE1->E1_SALDO == SE1->E1_VALOR .AND. !empty(Posicione("SAE",1,xFilial("SAE",iif(lMVVFilOri,oGet1:aCols[nI][n43PosFOr],oGet1:aCols[nI][n43PosFil]))+Alltrim(oGet1:aCols[nI][n43PosCDes]),"AE_COD")) //oGet1:aCols[nI][18] > 0 //se tit totalmente aberto e é de adm financeira

							_nVlrLiq := Round( iif(empty(SE1->E1_VLRREAL),SE1->E1_VALOR,SE1->E1_VLRREAL)*(1-(oGet1:aCols[nI][n43PosTaxa]/100)), TAMSX3("E1_VALOR")[2] )

							if _nVlrLiq <> SE1->E1_VALOR //se realmente precisa alterar valor
                                
                                //Montando array para execauto
								aFin040 := {}
								AADD(aFin040, {"E1_FILIAL"	,SE1->E1_FILIAL		,Nil } )
								AADD(aFin040, {"E1_PREFIXO"	,SE1->E1_PREFIXO	,Nil } )
								AADD(aFin040, {"E1_NUM"		,SE1->E1_NUM		,Nil } )
								AADD(aFin040, {"E1_PARCELA"	,SE1->E1_PARCELA  	,Nil } )
								AADD(aFin040, {"E1_TIPO"	,SE1->E1_TIPO	   	,Nil } )
								AADD(aFin040, {"E1_CLIENTE"	,SE1->E1_CLIENTE	,Nil } )
								AADD(aFin040, {"E1_LOJA"	,SE1->E1_LOJA		,Nil } )

								AADD(aFin040, {"E1_VALOR"   ,_nVlrLiq	,Nil})

								lMsErroAuto := .F. // variavel interna da rotina automatica
								lMsHelpAuto := .F.

                                cBkpOrigem := SE1->E1_ORIGEM

                                If  Alltrim(SE1->E1_ORIGEM) == "LOJA701" .And. SE1->E1_TIPO $ 'CC |CD |PX |PD '
                                    //TITPGPIXCART - O título não pode ser alterado pois foi originado pela rotina de Venda Assistida e pago com PIX ou cartões de débito e crédito
                                    //apaga a origem para ser possível alteração/exclusão do titulo
                                    RecLock("SE1",.F.)
                                        SE1->E1_ORIGEM := ""
                                    SE1->(MsUnlock())
                                EndIf

								//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
								//³ Chama a funcao de gravacao automatica do FINA040                        ³
								//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
								MSExecAuto({|x,y| FINA040(x,y)},aFin040, 4)

								if lMsErroAuto
									MostraErro()
								endif

                                //volta a origem 
                                RecLock("SE1",.F.)
                                    SE1->E1_ORIGEM := cBkpOrigem
                                SE1->(MsUnlock())
							endif
						endif
					Next nX
				Endif

                if !lContinua
					EXIT
				endif

				//Grava Log
				RecLock("U69",.T.)
				U69->U69_FILIAL := xFilial("U69",iif(lMVVFilOri,oGet1:aCols[nI][n43PosFOr],oGet1:aCols[nI][n43PosFil]))
				U69->U69_USER	:= cUserName
				U69->U69_DATA	:= dDataBase
				U69->U69_HORA	:= Time()
				U69->U69_DOC	:= oGet1:aCols[nI][n43PosNum]
				If !Empty( U69->( FieldPos( "U69_ROTINA" ) ) )
					U69->U69_ROTINA := FunName()
				EndIf
				If !Empty( U69->( FieldPos( "U69_DATCTB" ) ) )
					U69->U69_DATCTB	:= dDtCTB
				EndIf
				U69->U69_SERIE	:= oGet1:aCols[nI][n43PosPfx]
				U69->U69_CLIENT	:= oGet1:aCols[nI][n43PosCli]
				U69->U69_LOJA	:= oGet1:aCols[nI][n43PosLoja]
				U69->U69_NVCLI	:= oGet1:aCols[nI][n43PosCDes]
				U69->U69_NVLOJA	:= oGet1:aCols[nI][n43PosLDes]
				U69->U69_MOTIVO	:= oGet1:aCols[nI][n43PosMoti]
				U69->U69_DESFEI	:= "S"
				U69->(MsUnlock())

			Endif
		Next nI

		// Finaliza a transacao - Dt. 19/07/2016
		END TRANSACTION

		If nAux > 0
			MsgInfo("Operação realizada com sucesso!!","Atenção")
			oDlg:End()
		Else
			MsgInfo("Nenhum registro selecionado ou ausência do cliente a ser alterado.","Atenção")
		Endif

        DbUnlockAll()
	Endif
Endif

Return

//------------------------------------------------
// seleciona cliente para troca
//------------------------------------------------
Static Function SelCli()

    Local nI
    Local nAux			:= 0
    Local cFilTitMk := ""
    Local bValidAdm := {|| cCli := PadR(cAdmF, TamSX3("A1_COD")[1]), cLojaCli:=PadR("01", TamSX3("A1_LOJA")[1]), ValCli(1, cFilTitMk) }
    Local lHasCard := .F.
    Local lHasNoCard := .F.
    Local lBkpAdmFin := lAdmFin
    Local cBkpFilAnt := cFilAnt

    Private oSay1, oSay2, oSay3, oSay4
    Private oCli, oLojaCli, oMot, oAdmF

    Private cCli 		:= Space(TamSx3("A1_COD")[1])
    Private cLojaCli	:= Space(TamSx3("A1_LOJA")[1])
    Private cMot		:= Space(2)
    Private cAdmF		:= Space(TamSx3("A3_COD")[1])

    Private oNomeCli
    Private cNomeCli	:= ""

    Private oDescMot
    Private cDescMot	:= ""

    Private oButton1, oButton2

    Static oDlgCli

    For nI := 1 To Len(oGet1:aCols)
        If oGet1:aCols[nI][n43PosMark] == "LBOK"
            nAux++
            if empty(cFilTitMk)
                cFilTitMk := oGet1:aCols[nI][n43PosFOr]
            endif
            if Alltrim(oGet1:aCols[nI][n43PosTipo]) $ "CC/CD"
                lHasCard := .T.
            endif
            if !(Alltrim(oGet1:aCols[nI][n43PosTipo]) $ "CC/CD")
                lHasNoCard := .T.
            endif
        Endif
    Next

    If nAux == 0
        MsgInfo("Nenhum registro selecionado!","Atenção")
        Return
    Endif

    if lHasCard .AND. lHasNoCard
        MsgInfo("Selecione separadamente titulos de Cartão de outros tipos de titulos!","Atenção")
        Return
    endif

    if lHasCard
        lAdmFin := .T.
        if !empty(cFilTitMk)
            cFilAnt := cFilTitMk
        endif
    endif

    DEFINE MSDIALOG oDlgCli TITLE "Selecionar Cliente" From 000,000 TO 125,600 PIXEL

    if lAdmFin
        @ 005, 005 SAY oSay1 PROMPT "Adm Fin.:" SIZE 030, 007 OF oDlgCli COLORS CLR_BLUE, 16777215 PIXEL
        @ 005, 030 MSGET oAdmF VAR cAdmF SIZE 040, 010 OF oDlgCli COLORS 0, 16777215 HASBUTTON PIXEL Valid empty(cAdmF) .OR. EVal(bValidAdm) F3 "SAE" Picture "@!"
        @ 007, 130 SAY oNomeCli PROMPT cNomeCli SIZE 120, 007 OF oDlgCli COLORS 0, 16777215 PIXEL

        cMot := SuperGetMv("MV_XMOTEXC",,cMot) //define motivo padrão de alteração de sacado quando vem da rotina Extrato Cartao
        if !empty(cMot)
            ValMot(.F.)
        endif
    else
        @ 005, 005 SAY oSay1 PROMPT "Cliente:" SIZE 030, 007 OF oDlgCli COLORS CLR_BLUE, 16777215 PIXEL
        @ 005, 030 MSGET oCli VAR cCli SIZE 040, 010 OF oDlgCli COLORS 0, 16777215 HASBUTTON PIXEL Valid IIF(!Empty(cCli),ValCli(1, cFilTitMk),.T.) F3 "SA1" Picture "@!"
        @ 005, 080 SAY oSay2 PROMPT "Loja:" SIZE 030, 007 OF oDlgCli COLORS CLR_BLUE, 16777215 PIXEL
        @ 005, 100 MSGET oLojaCli VAR cLojaCli SIZE 020, 010 OF oDlgCli COLORS 0, 16777215 PIXEL Valid IIF(!Empty(cLojaCli),ValCli(2, cFilTitMk),.T.) Picture "@!"
        @ 007, 130 SAY oNomeCli PROMPT cNomeCli SIZE 120, 007 OF oDlgCli COLORS 0, 16777215 PIXEL
    endif

    @ 021, 005 SAY oSay3 PROMPT "Motivo:" SIZE 030, 007 OF oDlgCli COLORS CLR_BLUE, 16777215 PIXEL
    @ 021, 030 MSGET oMot VAR cMot SIZE 020, 010 OF oDlgCli COLORS 0, 16777215 HASBUTTON  PIXEL Valid IIF(!Empty(cMot),ValMot(),.T.) F3 "XT" Picture "@!"
    @ 023, 065 SAY oDescMot PROMPT cDescMot SIZE 120, 007 OF oDlgCli COLORS 0, 16777215 PIXEL

    //Linha horizontal
    @ 040, 005 SAY oSay4 PROMPT Repl("_",290) SIZE 290, 007 OF oDlgCli COLORS CLR_GRAY, 16777215 PIXEL

    @ 051, 210 BUTTON oButton1 PROMPT "Confirmar" SIZE 040, 010 OF oDlgCli ACTION ConfSel() PIXEL
    @ 051, 255 BUTTON oButton2 PROMPT "Fechar" SIZE 040, 010 OF oDlgCli ACTION oDlgCli:End() PIXEL

    lAdmFin := lBkpAdmFin

    ACTIVATE MSDIALOG oDlgCli CENTERED

    cFilAnt := cBkpFilAnt
    
Return

//-------------------------------------
// valida campo cliente
//-------------------------------------
Static Function ValCli(_nOpc, cFilTitMk)

    Local lRet := .T.
    Local aAreaSAE := SAE->( GetArea() )
    Local lMVVFilOri	:= len(cFilAnt) <> len(AlltriM(xFilial("SE1"))) //SuperGetMV("MV_XFILORI", .F., .F.)
    Local nI

    dbSelectArea("SA1")
    SA1->(dbSetOrder(1))

    If _nOpc == 1
        If !Empty(cLojaCli)
            If !SA1->(dbSeek(xFilial("SA1")+cCli+cLojaCli))
                lRet := .F.
                cNomeCli := ""
                if lAdmFin
                    MsgInfo("Cliente relacionado a Adm Financeira não encontrada!!","Atenção")
                else
                    MsgInfo("Cliente inválido!!","Atenção")
                endif
            Endif
        Else
            If !SA1->(dbSeek(xFilial("SA1")+cCli))
                lRet := .F.
                cNomeCli := ""
                MsgInfo("Cliente inválido!!","Atenção")
            Endif
        Endif
    Else
        If Empty(cCli)
            lRet := .F.
            MsgInfo("Campo <Cliente> obrigatório!!","Atenção")
        Else
            If !SA1->(dbSeek(xFilial("SA1")+cCli+cLojaCli))
                lRet := .F.
                cNomeCli := ""
                MsgInfo("Cliente inválido!!","Atenção")
            Endif
        Endif
    Endif

    If lRet .AND. lAdmFin
        DbSelectArea("SAE")
        If !SAE->( DbSetOrder(2), MsSeek(xFilial("SAE", cFilTitMk)+Alltrim(cCli)) )
            lRet := .F.
            cNomeCli := ""
            MsgInfo("O Cliente deve ser uma Adm. Financeira!!","Atenção")
        EndIf
        RestArea(aAreaSAE)
    EndIf

    if lRet
        For nI := 1 To Len(oGet1:aCols)
            If oGet1:aCols[nI][n43PosMark] == "LBOK"
                //TODO tratar busca pelo campo Adm
                if len(Alltrim(cCli))==3 .AND. empty(Posicione("SAE",1,xFilial("SAE",iif(lMVVFilOri,oGet1:aCols[nI][n43PosFOr],oGet1:aCols[nI][n43PosFil]))+Alltrim(cCli),"AE_COD"))
                    lRet := .F.
                    cNomeCli := ""
                    MsgInfo("O Cliente selecionado é uma Adm. Financeira, mas esta Adm Fin. não pertence a filial do titulo ["+oGet1:aCols[nI][n43PosNum]+"].","Atenção")
                    EXIT
                endif
            Endif
        Next nI
    endif

    If lRet .And. (!Empty(cCli) .And. !Empty(cLojaCli))
        cNomeCli := SA1->A1_NOME
    Endif

    oNomeCli:Refresh()

Return lRet

//------------------------------------------------
//valida motivo
//------------------------------------------------
Static Function ValMot(lRefresh)

    Local lRet := .T.
    Default lRefresh := .T.

    cDescMot := Posicione("SX5",1,xFilial("SX5")+"XT"+cMot,"X5_DESCRI")

    If empty(cDescMot)
        lRet 		:= .F.
        MsgInfo("Motivo inválido!!","Atenção")
    Endif

    if lRefresh
        oDescMot:Refresh()
    endif

Return lRet

//--------------------------------------------
// confirma selecao cliente
//--------------------------------------------
Static Function ConfSel()
    Local nI
    Local nValTaxAdm, aAdmValTax, nQtdParc
    Local cChvTransCC := ""
    Local lMVVFilOri	:= len(cFilAnt) <> len(AlltriM(xFilial("SE1"))) //SuperGetMV("MV_XFILORI", .F., .F.)
    
    If !Empty(cNomeCli)

        If !Empty(cMot)

            For nI := 1 To Len(oGet1:aCols)
                If oGet1:aCols[nI][n43PosMark] == "LBOK"
                    oGet1:aCols[nI][n43PosCDes] := cCli
                    oGet1:aCols[nI][n43PosLDes] := cLojaCli
                    oGet1:aCols[nI][n43PosNDes] := cNomeCli
                    oGet1:aCols[nI][n43PosMoti] := cMot
                    oGet1:aCols[nI][n43PosDMot]	:= cDescMot
                    //TODO tratar busca pelo campo Adm
                    if len(Alltrim(cCli))==3 .AND. !empty(Posicione("SAE",1,xFilial("SAE",iif(lMVVFilOri,oGet1:aCols[nI][n43PosFOr],oGet1:aCols[nI][n43PosFil]))+Alltrim(cCli),"AE_COD"))
                        
                        //Buscando qtd parcelas
                        nQtdParc := 0
                        if Alltrim(oGet1:aCols[nI][n43PosTipo]) == "CC"
                            cChvTransCC := oGet1:aCols[nI][n43PosFil]+oGet1:aCols[nI][n43PosCli]+oGet1:aCols[nI][n43PosLoja]+oGet1:aCols[nI][n43PosPfx]+oGet1:aCols[nI][n43PosNum]+oGet1:aCols[nI][n43PosTipo]+oGet1:aCols[nI][n43PosCAut]+oGet1:aCols[nI][n43PosNSU]
                            aEval(oGet1:aCols, {|x| iif(x[n43PosFil]+x[n43PosCli]+x[n43PosLoja]+x[n43PosPfx]+x[n43PosNum]+x[n43PosTipo]+x[n43PosCAut]+x[n43PosNSU] == cChvTransCC , nQtdParc++,) })
                        endif
                        if nQtdParc == 0
                            nQtdParc := 1
                        endif

                        //BUSCANDO TAXA ADM FINANCEIRA PARA CARTAO
                        nValTaxAdm := 0
                        If ExistFunc("LJ7_TXADM") .AND. MEN->(ColumnPos("MEN_TAXADM")) > 0
                            //LJ7_TxAdm(cCodAdmin, nParc, nValCC)
                            aAdmValTax := LJ7_TxAdm( SAE->AE_COD, nQtdParc, oGet1:aCols[nI][n43PosVlr] )
                            If Len(aAdmValTax) > 0
                                nValTaxAdm := aAdmValTax[3]
                            EndIf
                        EndIf
                        If nValTaxAdm == 0
                            nValTaxAdm := SAE->AE_TAXA
                        EndIf

                        oGet1:aCols[nI][n43PosTaxa] := nValTaxAdm
                    endif
                Endif
            Next

            oDlgCli:End()
            oGet1:oBrowse:Refresh()
        Else
            MsgInfo("Obrigatoriamente um motivo deve ser selecionado!!","Atenção")
        Endif
    Else
        MsgInfo("Obrigatoriamente um cliente deve ser selecionado!!","Atenção")
    Endif

Return

//---------------------------------------------------------------
// monta perguntas
//---------------------------------------------------------------
Static Function ValidPerg()

    Local aParamBox := {}

    //inicializo as variaveis
    aParam[01] := Space(len(cFilAnt))
    aParam[02] := Space(len(cFilAnt))
    aParam[03] := STOD("")
    aParam[04] := STOD("")
    aParam[05] := Space(TamSX3("E1_NUM")[1])
    aParam[06] := Space(TamSX3("E1_NUM")[1])
    aParam[07] := Space(TamSX3("L1_PLACA")[1])
    aParam[08] := Space(TamSX3("E1_CLIENTE")[1])
    aParam[09] := Space(TamSX3("E1_CLIENTE")[1])
    aParam[10] := Space(TamSX3("E1_LOJA")[1])
    aParam[11] := Space(TamSX3("E1_LOJA")[1])
    aParam[12] := 0
    aParam[13] := 0
    aParam[14] := Space(TamSX3("E1_TIPO")[1])

    aAdd(aParamBox,{1,"Filial de ",	aParam[01], "@!",'.T.',"SM0" ,'.T.', 40, .F.})
    aAdd(aParamBox,{1,"Filial ate",	aParam[02], "@!",'.T.',"SM0" ,'.T.', 40, .T.})
    aAdd(aParamBox,{1,"Emissao de", aParam[03], "",'.T.',"" ,'.T.', 50, .T.})
    aAdd(aParamBox,{1,"Emissao ate", aParam[04], "",'.T.',"" ,'.T.', 50,  .T.})
    aAdd(aParamBox,{1,"Título de", aParam[05], PESQPICT("SE1", "E1_NUM"),'.T.',"SF2" ,'.T.', 60, .F.})
    aAdd(aParamBox,{1,"Título ate", aParam[06], PESQPICT("SE1", "E1_NUM"),'.T.',"SF2" ,'.T.', 60, .T.})
    aAdd(aParamBox,{1,"Placa", aParam[07], PESQPICT("SL1", "L1_PLACA"),'.T.',"DA3" ,'.T.', 50, .F.})
    aAdd(aParamBox,{1,"Cliente de", aParam[08], PESQPICT("SE1", "E1_CLIENTE"),'.T.',"SA1" ,'.T.', 50, .F.})
    aAdd(aParamBox,{1,"Cliente ate", aParam[09], PESQPICT("SE1", "E1_CLIENTE"),'.T.',"SA1" ,'.T.', 50, .T.})
    aAdd(aParamBox,{1,"Loja de", aParam[10], PESQPICT("SE1", "E1_LOJA"),'.T.',"" ,'.T.', 30, .F.})
    aAdd(aParamBox,{1,"Loja ate", aParam[11], PESQPICT("SE1", "E1_LOJA"),'.T.',"" ,'.T.', 30, .T.})
    aAdd(aParamBox,{1,"Valor de", aParam[12], PESQPICT("SE1", "E1_VALOR"),'.T.',"" ,'.T.', 60, .F.})
    aAdd(aParamBox,{1,"Valor ate", aParam[13], PESQPICT("SE1", "E1_VALOR"),'.T.',"" ,'.T.', 60, .F.})
    aAdd(aParamBox,{1,"Forma de Pagto.", aParam[14], PESQPICT("SE1", "E1_TIPO"),'.T.',"24" ,'.T.', 30, .F.})

Return ParamBox(aParamBox,"PARÂMETROS",@aParam)


