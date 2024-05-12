#include "protheus.ch"
#include "topconn.ch"

/*/{Protheus.doc} TRETE010
Informativo Divergência LMC
Faz Comparativo entre gravado no históricio (U0I) e leitura em tempo real

@author Danilo Brito
@since 20/02/2015
@version 1.0
@param Data e Produto
@return nulo
/*/
User Function TRETE039(dData,cProd,lBrowse)

    Local aDadosLMC
    Local aDadosU0I
    Local bSort := {|x, y| x[1]+x[2] < y[1]+y[2] }
    Local lDiverg := .F.
    Local nX, nPosAux
    Local aOpcAviso
    Local aArea := GetArea()
    Local aAreaMIE := MIE->(GetArea())
    Local aAreaU0I := U0I->(GetArea())
    Local nTolDivSMID := SuperGetMv("MV_XTLDLMC",,0.5)
    Default lBrowse := .F.

    Private oLMC

    //verifico se tem algo gravado na U0I, se nao retorna
    DbSelectArea("U0I")
	U0I->(DbSetOrder(1)) //U0I_FILIAL+DTOS(U0I_DATA)+U0I_PROD+U0I_TANQUE+U0I_BICO
	if !U0I->(DbSeek(xFilial("U0I")+DTOS(dData)+cProd ))
        if lBrowse
            MsgInfo("Não há dados de histórigo registrado.","Atenção")
        endif
        Return
    endif

    oLMC := TLmcLib():New(cProd, dData)
    oLMC:SetTRetVen(2) //1=Vlr Total Vendas; 2=Array Dados; 3=Qtd Registros
	oLMC:SetDRetVen({"_TANQUE", "_BICO", "_NLOGIC", "_BOMBA", "_FECH", "_ABERT", "_AFERIC", "_VDBICO","_VDSUMMID"})

    //retorna dados de vendas
	aDadosLMC := oLMC:RetVen(.T.) //via query

    oLMC:SetDRetVen({"_TANQUE", "_BICO", "_NLOGIC", "_BOMBA", "_FECH", "_ABERT", "_AFERIC", "_VDBICO", "U0I_ATUALI"})
	aDadosU0I := oLMC:RetVen(.F.) //via U0I

    //ordeno por tanque + bico
    aSort(aDadosLMC,,,bSort)
    aSort(aDadosU0I,,,bSort)

    //comparando divergências
    if len(aDadosLMC) <> len(aDadosU0I)
        lDiverg := .T.
    else
        for nX := 1 to len(aDadosLMC)
            //verifico se tem na U0I
            nPosAux := aScan(aDadosU0I, {|x| x[1]+x[2] == aDadosLMC[nX][1]+aDadosLMC[nX][2]})
            if nPosAux > 0
                if aDadosLMC[nX][5] <> aDadosU0I[nPosAux][5] //fecha
                    lDiverg := .T.
                    EXIT
                elseif aDadosLMC[nX][6] <> aDadosU0I[nPosAux][6] //abert
                    lDiverg := .T.
                    EXIT
                elseif aDadosLMC[nX][7] <> aDadosU0I[nPosAux][7] //aferic
                    lDiverg := .T.
                    EXIT
                elseif aDadosLMC[nX][8] <> aDadosU0I[nPosAux][8] //vd bico
                    lDiverg := .T.
                    EXIT
                elseif aDadosLMC[nX][9] <> aDadosLMC[nX][8] //_VDSUMMID
                    if abs(aDadosLMC[nX][8] - aDadosLMC[nX][9]) > nTolDivSMID
                        lDiverg := .T.
                        EXIT
                    endif
                endif
            else
                lDiverg := .T.
                EXIT
            endif
        next nX
    endif

    //se chamou do browse, abre tela direto
    if lBrowse
        DoTelaDiv(dData, cProd, aDadosLMC, aDadosU0I)

    //senao, avisa se tem divergencia
    elseif lDiverg
        aOpcAviso := {"Fechar","Detalhar"}
        nX := Aviso("Divergência Apuração Vendas LMC", ;
                "Foi detectado divergência de venda entre a apuração LMC gravada (histórico)"+ ;
                " e a apuração realizada neste momento." + Chr(13)+Chr(10) + ;
                "DATA: "+DTOC(dData) + Chr(13)+Chr(10) + "Produto: " + Alltrim(cProd) + " - " + Posicione("SB1",1,xFilial("SB1")+cProd,"B1_DESC"), ;
                aOpcAviso, 2)
        if nX == 2
            DoTelaDiv(dData, cProd, aDadosLMC, aDadosU0I)
        endif
    endif

    RestArea(aAreaU0I)
    RestArea(aAreaMIE)
    RestArea(aArea)

Return


/*/{Protheus.doc} DoTelaDiv
Monta tela de mostrar divergencias

@type  Static Function
@author Danilo Brito
@since 11/08/2020
@version 1
/*/
Static Function DoTelaDiv(dData, cProd, aDadosLMC, aDadosU0I)
    
    Local cTitulo := "Divergência Apuração Vendas LMC"
    Local oButton1, oButton2
    Local aObjects, aSizeAut, aPosObj, aInfo
    Local cCab := "DATA: "+DTOC(dData) + space(10) + "Produto: " + Alltrim(cProd) + " - " + Posicione("SB1",1,xFilial("SB1")+cProd,"B1_DESC")
    Local oGet1
    Local oGet2
    Local oFontTit := TFont():New('Arial',,22,.T.,.T.)
	Local oFontGrid := TFont():New('Arial',,18,.T.,.T.)
    Local nX, nPosAux
    Local lJaAtual := .F.
    Local nTotAferic := 0
    Local nTotVendas := 0
    Local nTotSUMMID := 0
    Local nTolDivSMID := SuperGetMv("MV_XTLDLMC",,0.5)

    Static oDlg

    aObjects := {}
    aSizeAut := MsAdvSize()

    //Largura, Altura, Modifica largura, Modifica altura
    aAdd(aObjects, {100, 045, .T., .T.}) //grid 1
    aAdd(aObjects, {100, 055, .T., .T.}) //grid 2

    aInfo 	:= { aSizeAut[ 1 ], aSizeAut[ 2 ], aSizeAut[ 3 ], aSizeAut[ 4 ], 3, 3 }
    aPosObj := MsObjSize( aInfo, aObjects, .T. )

    DEFINE MSDIALOG oDlg TITLE cTitulo From aSizeAut[7],0 TO aSizeAut[6],aSizeAut[5] OF oMainWnd PIXEL

    TSay():New( 005, 005,{|| cCab }, oDlg,,oFontTit,,,,.T.,CLR_BLUE,,aPosObj[1,4],16 )

    //Apurado
    TSay():New( aPosObj[1,1]-10,aPosObj[1,2]+5,{|| "Vendas LMC Apurado" }, oDlg,,oFontGrid,,,,.T.,,,200,15 )
    @ aPosObj[1,1]-8,aPosObj[1,2] SAY ("Tolerancia Dif. (MV_XTLDLMC):  " + Alltrim(Transform(nTolDivSMID,"@E 99,999.99")) ) SIZE aPosObj[1,4]-5,15 OF oDlg COLOR 0, 16777215 PIXEL RIGHT
	TSay():New( aPosObj[1,1]-8,aPosObj[1,2],{|| Replicate("_",aPosObj[1,4]) }, oDlg,,oFontGrid,,,,.T.,,,aPosObj[1,4]-5,15 )
    oGet1 := GetDados1(aPosObj[1,1]+3,aPosObj[1,2],aPosObj[1,3],aPosObj[1,4], .T.)
    oGet1:aCols := aClone(aDadosLMC)
    aEval(oGet1:aCols, {|x| aSize(x, len(x)+1), aIns(x, 1), x[1]:="BR_VERDE" }) //ajusto acols coluna legenda, posicao 1
    aEval(oGet1:aCols, {|x| aSize(x, len(x)+1), aIns(x, len(x)-1), x[len(x)-1]:=0 }) //ajusto acols coluna DIFVDBICO, posicao 11

    //Gravado Histórico U0I
    TSay():New( aPosObj[2,1],aPosObj[2,2]+5,{|| "Vendas LMC Histórico" }, oDlg,,oFontGrid,,,,.T.,,,200,15 )
	TSay():New( aPosObj[2,1]+2,aPosObj[2,2],{|| Replicate("_",aPosObj[2,4]) }, oDlg,,oFontGrid,,,,.T.,,,aPosObj[2,4]-5,15 )
    oGet2 := GetDados1(aPosObj[2,1]+12,aPosObj[2,2],aPosObj[2,3]-20,aPosObj[2,4])
    oGet2:aCols := aClone(aDadosU0I)
    aEval(oGet2:aCols, {|x| aSize(x, len(x)+1), aIns(x, 1), x[1]:="BR_VERDE" }) //ajusto acols coluna legenda

    //Carrego legenda grid 1
    for nX:=1 to len(aDadosLMC)
        //bico existe no histórico?
        nPosAux := aScan(aDadosU0I, {|x| x[1]+x[2] == aDadosLMC[nX][1]+aDadosLMC[nX][2]})
        if nPosAux > 0
            if aDadosLMC[nX][5] <> aDadosU0I[nPosAux][5] //fecha
                oGet1:aCols[nX][1] := "BR_VERMELHO"
            elseif aDadosLMC[nX][6] <> aDadosU0I[nPosAux][6] //abert
                oGet1:aCols[nX][1] := "BR_VERMELHO"
            elseif aDadosLMC[nX][7] <> aDadosU0I[nPosAux][7] //aferic
                oGet1:aCols[nX][1] := "BR_VERMELHO"
            elseif aDadosLMC[nX][8] <> aDadosU0I[nPosAux][8] //vd bico
                oGet1:aCols[nX][1] := "BR_VERMELHO"
            elseif aDadosLMC[nX][8] <> aDadosLMC[nX][9] //_VDSUMMID
                if abs(aDadosLMC[nX][8] - aDadosLMC[nX][9]) > nTolDivSMID
                    oGet1:aCols[nX][1] := "BR_VERMELHO"
                endif
            endif
            oGet1:aCols[nX][11] := aDadosLMC[nX][8] - aDadosLMC[nX][9] //DIFVDBICO
        else
            oGet1:aCols[nX][1] := "BR_VERMELHO"
        endif

        nTotAferic += aDadosLMC[nX][7]
        nTotVendas += aDadosLMC[nX][8]
        nTotSUMMID += aDadosLMC[nX][9]
    next nX
    
    aAdd(oGet1:aCols,{"","TOTAL","","","",0,0,nTotAferic,nTotVendas,nTotSUMMID, nTotVendas-nTotSUMMID ,.F.})
    nTotAferic := 0
    nTotVendas := 0

    //Carrego legenda grid 2
    for nX:=1 to len(aDadosU0I)
        //bico existe no atual?
        nPosAux := aScan(aDadosLMC, {|x| x[1]+x[2] == aDadosU0I[nX][1]+aDadosU0I[nX][2]})
        if nPosAux > 0
            if aDadosU0I[nX][5] <> aDadosLMC[nPosAux][5] //fecha
                oGet2:aCols[nX][1] := "BR_VERMELHO"
            elseif aDadosU0I[nX][6] <> aDadosLMC[nPosAux][6] //abert
                oGet2:aCols[nX][1] := "BR_VERMELHO"
            elseif aDadosU0I[nX][7] <> aDadosLMC[nPosAux][7] //aferic
                oGet2:aCols[nX][1] := "BR_VERMELHO"
            elseif aDadosU0I[nX][8] <> aDadosLMC[nPosAux][8] //vd bico
                oGet2:aCols[nX][1] := "BR_VERMELHO"
            endif
        else
            oGet2:aCols[nX][1] := "BR_VERMELHO"
        endif

        if !lJaAtual .AND. aDadosU0I[nX][9]=="S" //atualizado?
            lJaAtual := .T.
        endif

        nTotAferic += aDadosU0I[nX][7]
        nTotVendas += aDadosU0I[nX][8]
    next nX
    
    aAdd(oGet2:aCols,{"","TOTAL","","","",0,0,nTotAferic,nTotVendas,.F.})

    //legenda totais
    oGet1:aCols[len(oGet1:aCols)][1] := iif(oGet1:aCols[len(oGet1:aCols)][9] == nTotVendas, "BR_VERDE","BR_VERMELHO")
    oGet2:aCols[len(oGet2:aCols)][1] := iif(oGet1:aCols[len(oGet1:aCols)][9] == nTotVendas, "BR_VERDE","BR_VERMELHO")
    if abs(oGet1:aCols[len(oGet1:aCols)][9] - oGet1:aCols[len(oGet1:aCols)][10]) > nTolDivSMID
        oGet1:aCols[len(oGet1:aCols)][1] := "BR_VERMELHO"
    endif

    //Botão Atualizar
    If cNivel == 9
        
        @ aPosObj[2,3]-15, aPosObj[2,4] - 190 BUTTON oButton3 PROMPT "Estornar At." SIZE 060, 013 OF oDlg ACTION iif(DoEstU0I(dData, cProd), oDlg:End(), ) PIXEL
        if !lJaAtual 
            oButton3:Disable()
        endif

        @ aPosObj[2,3]-15, aPosObj[2,4] - 125 BUTTON oButton2 PROMPT "Atualizar" SIZE 060, 013 OF oDlg ACTION iif(DoAtuU0I(dData, cProd, aDadosLMC, aDadosU0I, oGet1), oDlg:End(), ) PIXEL
        
        //se nao tem nenhuma divergencia, nao habilito botao
        if aScan(oGet1:aCols, {|x| x[1]=="BR_VERMELHO" }) == 0 .AND. aScan(oGet2:aCols, {|x| x[1]=="BR_VERMELHO" }) == 0
            oButton2:Disable()
        endif

    endif

    //Botão Fechar
    @ aPosObj[2,3]-15, aPosObj[2,4] - 60 BUTTON oButton1 PROMPT "Fechar" SIZE 060, 013 OF oDlg ACTION oDlg:End() PIXEL

    //Legendas
	@ aPosObj[2,3]-15, 010 BITMAP oLeg ResName "BR_VERDE" OF oDlg Size 10, 10 NoBorder When .F. PIXEL
	@ aPosObj[2,3]-15, 020 SAY "Sem Divergências" OF oDlg Color CLR_BLACK PIXEL

	@ aPosObj[2,3]-15, 070 BITMAP oLeg ResName "BR_VERMELHO" OF oDlg Size 10, 10 NoBorder When .F. PIXEL
	@ aPosObj[2,3]-15, 080 SAY "Com Divergência" OF oDlg Color CLR_BLACK PIXEL

    ACTIVATE MSDIALOG oDlg CENTERED

Return 

//-------------------------------------
//Monta newgetdados
//-------------------------------------
Static Function GetDados1(nTop,nLeft,nBottom,nRight,lVdBicoMID)

    Local nX
    Local aHeaderEx 	:= {}
    Local aColsEx 		:= {}
    Local aFieldFill 	:= {}

    Local aFields 		:= {"U0I_TANQUE","U0I_BICO","U0I_BOMBA","U0I_NLOGIC","U0I_ENCFEC","U0I_ENCABE","U0I_AFERIC","U0I_VDBICO"}
    Local aAlterFields 	:= {}

    aAdd(aHeaderEx, {" ","LEG",'@BMP',5,0,'','€€€€€€€€€€€€€€','C','','','',''})
    aAdd(aFieldFill, "BR_BRANCO")

    //Define field properties
    For nX := 1 to Len(aFields)
        If !empty(GetSx3Cache(aFields[nX],"X3_CAMPO"))
            aAdd(aHeaderEx, U_UAHEADER(aFields[nX]) )
            aAdd(aFieldFill, CriaVar(aFields[nX]))

            if lVdBicoMID .AND. aFields[nX] == "U0I_VDBICO"
                aHeaderEx[len(aHeaderEx)][1] += " (A)"

                aAdd(aHeaderEx, U_UAHEADER(aFields[nX]) )
                aHeaderEx[len(aHeaderEx)][1] := "Venda Soma Abast. (B)"
                aHeaderEx[len(aHeaderEx)][2] := "VDSUMMID"
                aAdd(aFieldFill, CriaVar(aFields[nX]))

                aAdd(aHeaderEx, U_UAHEADER(aFields[nX]) )
                aHeaderEx[len(aHeaderEx)][1] := "Diferença (A-B)"
                aHeaderEx[len(aHeaderEx)][2] := "DIFVDBICO"
                aAdd(aFieldFill, CriaVar(aFields[nX]))
            endif
        Endif
    Next

    aAdd(aFieldFill, .F.)
    aAdd(aColsEx, aFieldFill)

Return MsNewGetDados():New(nTop,nLeft,nBottom,nRight,,"AllwaysTrue","AllwaysTrue",,aAlterFields,,999,;
		"AllwaysTrue","","AllwaysTrue",oDlg,aHeaderEx,aColsEx)

/*/{Protheus.doc} DoAtuU0I
Atualiza tabela U0I com novos dados

@type  Static Function
@author Danilo Brito
@since 11/08/2020
@version 1
/*/
Static Function DoAtuU0I(dData, cProd, aDadosLMC, aDadosU0I, oGet1)
    
    Local nX
    Local aRecU0I := {}

    DbSelectArea("U0I")
	U0I->(DbSetOrder(1)) //U0I_FILIAL+DTOS(U0I_DATA)+U0I_PROD+U0I_TANQUE+U0I_BICO

    //verifica se tem algum LMC gerado com data superior
    if !VldAtu(dData,cProd)
        Return .F.
    endif

    BeginTran()

    //Gravo do grid atual na tabela U0I
    for nX:=1 to len(aDadosLMC)
        if oGet1:aCols[nX][1] == "BR_VERMELHO" //se tem divergência

            //bico existe no histórico?
            nPosAux := aScan(aDadosU0I, {|x| x[1]+x[2] == aDadosLMC[nX][1]+aDadosLMC[nX][2]})
            if nPosAux > 0 .AND. U0I->(DbSeek(xFilial("U0I")+DTOS(dData)+cProd+aDadosLMC[nX][1]+aDadosLMC[nX][2] ))
                Reclock("U0I", .F.) //altera
            else
                Reclock("U0I", .T.) //inclui
                U0I->U0I_FILIAL := xFilial("U0I")
                U0I->U0I_DATA 	:= dData
                U0I->U0I_PROD 	:= cProd
                U0I->U0I_TANQUE := aDadosLMC[nX][1]
                U0I->U0I_BICO 	:= aDadosLMC[nX][2]
                U0I->U0I_NLOGIC := aDadosLMC[nX][3]
                U0I->U0I_BOMBA 	:= aDadosLMC[nX][4]
                U0I->U0I_ENCFEC := 0
                U0I->U0I_ENCABE := 0
                U0I->U0I_AFERIC := 0
                U0I->U0I_VDBICO := -1
            endif

			U0I->U0I_ATUALI	:= "S" //teve atualização? S=Sim;N=Nao
            U0I->U0I_NEWEF  := aDadosLMC[nX][5]
            U0I->U0I_NEWEA  := aDadosLMC[nX][6]
            U0I->U0I_NEWAFE := aDadosLMC[nX][7]
            U0I->U0I_NEWVDB := aDadosLMC[nX][8]

			U0I->(MsUnlock())

            aadd(aRecU0I, U0I->(Recno()))
        endif
    next nX

    //marco X os U0I que não mais estão no grid atual, para ignorar nas leituras
    for nX:=1 to len(aDadosU0I)
        //bico existe no atual?
        nPosAux := aScan(aDadosLMC, {|x| x[1]+x[2] == aDadosU0I[nX][1]+aDadosU0I[nX][2]})
        if nPosAux == 0 //se nao existe
            Reclock("U0I", .F.)
            U0I->U0I_ATUALI	:= "X" //teve atualização? S=Sim;N=Nao
            U0I->(MsUnlock())
        endif
    next nX

    //Atualizando MIE
    AtualizMIE(dData, cProd, aDadosLMC)

    EndTran()
    MsgInfo("Dados venda LMC atualizados com sucesso!","Sucesso")

Return .T.

/*/{Protheus.doc} DoAtuU0I
Estorna Atualização da tabela U0I

@type  Static Function
@author Danilo Brito
@since 11/08/2020
@version 1
/*/
Static Function DoEstU0I(dData, cProd)
    
    Local aDadosU0I
    Local lRet := .F.

    if MsgYesNo("Confirma estornar para os valores da primeira leitura de vendas do LMC?","Atenção")

        BeginTran()

        DbSelectArea("U0I")
        U0I->(DbSetOrder(1)) //U0I_FILIAL+DTOS(U0I_DATA)+U0I_PROD+U0I_TANQUE+U0I_BICO
        if U0I->(DbSeek(xFilial("U0I")+DTOS(dData)+cProd ))
            While U0I->(!Eof()) .AND. U0I->(U0I_FILIAL+DTOS(U0I_DATA)+U0I_PROD) == xFilial("U0I")+DTOS(dData)+cProd
                
                if U0I->U0I_ATUALI $ "S,X"
                    Reclock("U0I", .F.)
                        //excluo linha criada pela atualização
                        if U0I->U0I_VDBICO == -1
                            U0I->(DbDelete())
                        else
                            U0I->U0I_ATUALI	:= "N"
                            U0I->U0I_NEWEF  := 0
                            U0I->U0I_NEWEA  := 0
                            U0I->U0I_NEWAFE := 0
                            U0I->U0I_NEWVDB := 0
                        endif
                    U0I->(MsUnlock())
                endif

                U0I->(DbSkip())
            Enddo
        endif

        //Atualizando MIE
        oLMC:SetDRetVen({"_TANQUE", "_BICO", "_NLOGIC", "_BOMBA", "_FECH", "_ABERT", "_AFERIC", "_VDBICO"})
	    aDadosU0I := oLMC:RetVen(.F.) //busco as U0I novamente já sem atualização
        AtualizMIE(dData, cProd, aDadosU0I)

        EndTran()

        MsgInfo("Dados venda LMC estornados com sucesso!","Sucesso")
        lRet := .T.

    endif

Return lRet

/*/{Protheus.doc} VldAtu
Valida Atualização
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@param nReg, numeric, descricao
@param cProd, characters, descricao
@type function
/*/
Static Function VldAtu(dData,cProd)

	Local lRet := .T.

	Local cQry	:= ""

	If Select("QRYLMC") > 0
		QRYLMC->(DbCloseArea())
	Endif

	cQry := "SELECT MIE.R_E_C_N_O_"
	cQry += " FROM "+RetSqlName("MIE")+" MIE"
	cQry += " WHERE MIE.D_E_L_E_T_ 	<> '*'"
	cQry += " AND MIE.MIE_FILIAL 	= '"+xFilial("MIE")+"'"
	cQry += " AND MIE.MIE_DATA	    > "+DTOS(dData)+""
	cQry += " AND MIE.MIE_CODPRO	= '"+cProd+"'"

	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\TRETM010.txt",cQry)
	TcQuery cQry NEW Alias "QRYLMC"

	If QRYLMC->(!EOF())
        MsgInfo('A atualização pode ser executada somente na última página LMC gerada.',"Atenção")
		lRet :=  .F.
	Endif

	If Select("QRYLMC") > 0
		QRYLMC->(DbCloseArea())
	Endif

Return lRet

/*/{Protheus.doc} AtualizMIE
Faz atualização da tabela principal MIE

@type  Static Function
@author Danilo Brito
@since 11/08/2020
@version 1
/*/
Static Function AtualizMIE(dData, cProd, aDadosVe)

    Local nX
    Local lRet := .T.
    Local lHasPG := .F.
    Local aPerda := {}
	Local aGanho := {}
    Local nPerda := 0
    Local nGanho := 0
    Local aFech := {}
    Local nQTQLMC := SuperGetMv("MV_XQTQLMC",,20) //Quantidade de tanques para apuração LMC

    DbSelectArea("MIE")
    MIE->(DbSetOrder(1)) //MIE_FILIAL+MIE_CODPRO+DTOS(MIE_DATA)+MIE_CODTAN+MIE_CODBIC
    If MIE->(DbSeek( xFilial("MIE")+cProd+DTOS(dData) ))
        
        //antes de mexer, vejo se teve perda ou ganho
        lHasPG := MIE->MIE_ESTFEC <> MIE->MIE_ESTESC 

        Reclock("MIE", .F.)

            //somando totais
            MIE->MIE_AFERIC := 0
            MIE->MIE_VENDAS := 0
            aEval(aDadosVe, {|x| MIE->MIE_AFERIC += x[7], MIE->MIE_VENDAS += x[8] })

            MIE->MIE_ESTESC := MIE->MIE_ABERT + MIE->MIE_ENTRAD - MIE->MIE_VENDAS


            //atualizando estoques finais
            //inicio com os estoques iniciais
            For nX := 1 To nQTQLMC
                if MIE->(FieldPos( 'MIE_ESTI'+StrZero(nX,2) ))>0 
                    aadd(aFech, {StrZero(nX,2),  MIE->&("MIE_ESTI" + StrZero(nX,2)) } )
                else
                    aadd(aFech, {StrZero(nX,2),  0 } )
                endif
            next nX
            //subtraio as vendas do tanque
            For nX := 1 To len(aDadosVe)
                aFech[val(aDadosVe[nX][1])][2] -= aDadosVe[nX][8]
            next nX
            //somo as entradas
            MHZ->(DbSetOrder(3)) //MHZ_FILIAL+MHZ_CODPRO+MHZ_LOCAL
            SF4->(DbSetOrder(1)) //F4_FILIAL+F4_CODIGO
            SF1->(DbSetOrder(1)) //F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO
            SD1->(DbSetOrder(6)) //D1_FILIAL+DTOS(D1_DTDIGIT)+D1_NUMSEQ
            If SD1->(DbSeek(xFilial("SD1")+DToS(dData)))
                While SD1->(!EOF()) .And. SD1->D1_FILIAL+DToS(SD1->D1_DTDIGIT) == xFilial("SD1")+DToS(dData)
                    If SD1->D1_TIPO $ "N/D" //Diferente de Complementos e Beneficiamento
                        If SF1->(DbSeek(xFilial("SF1")+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA))
                            If SF1->F1_XLMC == "S" //Considera LMC
                                If SF4->(DbSeek(xFilial("SF4")+SD1->D1_TES))
                                    If SF4->F4_ESTOQUE == "S" //Movimenta estoque
                                        If SD1->D1_COD == cProd
                                            //Tanque relacionado
                                            If MHZ->(DbSeek(xFilial("MHZ")+SD1->D1_COD+SD1->D1_LOCAL))
                                                While MHZ->(!Eof()) .AND. MHZ->MHZ_FILIAL + MHZ->MHZ_CODPRO + MHZ->MHZ_LOCAL == xFilial("MHZ")+SD1->D1_COD+SD1->D1_LOCAL
                                                    //If MHZ->MHZ_STATUS == "1" //Ativo
                                                    if ((MHZ->MHZ_STATUS == '1' .AND. MHZ->MHZ_DTATIV <= dData) .OR. (MHZ->MHZ_STATUS == '2' .AND. MHZ->MHZ_DTDESA >= dData))
                                                        aFech[val(MHZ->MHZ_CODTAN)][2] += SD1->D1_QUANT
                                                        EXIT
                                                    Endif
                                                    MHZ->(DbSkip())
                                                Enddo
                                            EndIf
                                        Endif
                                    Endif
                                Endif
                            Endif
                        Endif
                    Endif

                    SD1->(DbSkip())
                EndDo
            EndIf

            //se tem perda ou ganho, atualizo movimentos estoque a partir do que foi digitado nos fechamentos por tanque
            if lHasPG

                //estorna os movimentos de perda e ganho
                U_TRM010ES(dData, cProd)

                //monto perdas e ganhos
                For nX := 1 To nQTQLMC
                    if MIE->(FieldPos( 'MIE_VTAQ'+StrZero(nX,2) ))>0
                        if MIE->&("MIE_VTAQ" + StrZero(nX,2)) <> aFech[nX][2]
                            if aFech[nX][2] - MIE->&("MIE_VTAQ" + StrZero(nX,2)) > 0
                                aAdd(aPerda,{StrZero(nX,2), aFech[nX][2] - MIE->&("MIE_VTAQ" + StrZero(nX,2)) })
                                nPerda += aFech[nX][2] - MIE->&("MIE_VTAQ" + StrZero(nX,2)) 
                            else
                                aAdd(aGanho,{StrZero(nX,2),MIE->&("MIE_VTAQ" + StrZero(nX,2)) - aFech[nX][2] })
                                nGanho += MIE->&("MIE_VTAQ" + StrZero(nX,2)) - aFech[nX][2]
                            endif
                        endif
                    endif
                next nX

                If Len(aPerda) > 0
                    U_TRM010GE(1,dData, cProd,aPerda)
                Endif

                If Len(aGanho) > 0
                    U_TRM010GE(2,dData, cProd,aGanho)
                Endif

                If nGanho > nPerda
                    MIE->MIE_GANHOS := nGanho - nPerda
                    MIE->MIE_PERDA := 0
                Else
                    MIE->MIE_GANHOS := 0
                    MIE->MIE_PERDA := nPerda - nGanho
                Endif

                MIE->MIE_ESTFEC := MIE->MIE_ESTESC + MIE->MIE_GANHOS - MIE->MIE_PERDA

                //atualizo percentual de perda/ganho
                If MIE->(FieldPos("MIE_XPERGP")) > 0
                    MIE->MIE_XPERGP := Abs(((MIE->MIE_ESTFEC - MIE->MIE_ESTESC) / MIE->MIE_ESTESC) * 100)
                endif

            else //sem perda ou ganho, apenas atualiza os fechamentos por tanques
                MIE->MIE_ESTFEC := MIE->MIE_ESTESC

                For nX := 1 To nQTQLMC 
                    if MIE->(FieldPos( 'MIE_VTAQ'+StrZero(nX,2) ))>0
                        MIE->&("MIE_VTAQ" + StrZero(nX,2)) := aFech[nX][2] //MIE->&("MIE_ESTI" + StrZero(nX,2))
                    endif
                next nX
            endif

            /*/
                POSTO-655 - Vendas de setembro no LMC - Continuação chamado 632
                AJUSTE: o correto é pegar o preço dos abastecimentos do dia do LMC na tabela MID, 
                já que o LMC pode ser lançado alguns dias depois dos movimentos (abastecimentos), e o preço de tabela (DA1 -> DA1_PRCVEN) tenha sofrido alteração
            /*/
            MIE->MIE_VLRITE := MIE->MIE_VENDAS * MedPrecoVend(dData, cProd) //U_URetPrec(cProd,,.F.)
            MIE->MIE_ACUMUL := Acumulado(dData, cProd) + MIE->MIE_VLRITE

        MIE->(MsUnlock())
    else
        lRet := .F.
    endif

Return lRet


Static Function Acumulado(dData, cProd)

    Local cPriDia := cValToChar(Year(dData)) + StrZero(Month(dData),2) + "01"
    Local nAcum := 0

    if Day(dData) > 1
        //Acumulador Mensal
        If Select("QRYACUM") > 0
            QRYACUM->(dbCloseArea())
        Endif

        cQry := "SELECT SUM(MIE_VLRITE) AS VLR"
        cQry += " FROM "+RetSqlName("MIE")+""
        cQry += " WHERE D_E_L_E_T_ 	<> '*'"
        cQry += " AND MIE_FILIAL	= '"+xFilial("MIE")+"'"
        cQry += " AND MIE_CODPRO	= '"+cProd+"'"
        cQry += " AND MIE_DATA		BETWEEN '"+cPriDia+"'  AND '"+DToS(dData - 1)+"'

        cQry := ChangeQuery(cQry)
        //MemoWrite("c:\temp\RPOS011.txt",cQry)
        TcQuery cQry NEW Alias "QRYACUM"

        If QRYACUM->(!EOF())
            nAcum := QRYACUM->VLR
        Endif

        If Select("QRYACUM") > 0
            QRYACUM->(dbCloseArea())
        Endif
    endif

Return nAcum


Static Function MedPrecoVend(dData, cProd, cFilPes)

    Local nPrcVen := U_URetPrec(cProd,,.F.)

    Default cFilPes := xFilial("MID")

    //média preço de venda
    If Select("QRYAVG") > 0
        QRYAVG->(dbCloseArea())
    Endif

    //cQry := "SELECT AVG(ISNULL(MID_PREPLI, 0)) AS VLR"
    cQry := "SELECT (SUM(MID_LITABA * MID_PREPLI) / SUM(MID_LITABA) AS VLR" //média ponderada
    cQry += CRLF + " FROM "+RetSqlName("MID")+""
    cQry += CRLF + " WHERE D_E_L_E_T_ = ' '"
    cQry += CRLF + " AND MID_FILIAL	= '"+cFilPes+"'"
    cQry += CRLF + " AND MID_XPROD	= '"+cProd+"'"
    cQry += CRLF + " AND MID_DATACO	= '"+DTOS(dData)+"'"
    cQry += CRLF + "GROUP BY MID_FILIAL, MID_XPROD, MID_DATACO"

    cQry := ChangeQuery(cQry)
    TcQuery cQry NEW Alias "QRYAVG"

    If QRYAVG->(!EOF())
        nPrcVen := Round(QRYAVG->VLR,TamSX3("MID_PREPLI")[2])
    Endif

    If Select("QRYAVG") > 0
        QRYAVG->(dbCloseArea())
    Endif

Return nPrcVen


User Function TRETE39A()

	Local aParamBox := {}
	Private aParam := Array(4)

	aParam[01] := xFilial("MIE")
	aParam[02] := Space(TamSX3("B1_COD")[1])
	aParam[03] := STOD("")
	aParam[04] := STOD("")

	aAdd(aParamBox,{1,"Filial  ", aParam[01], "@!",'.T.',"SM0" ,'.T.', 40, .F.})
	aAdd(aParamBox,{1,"Produto ", aParam[02], "","","SB1","",0,.F.})
	aAdd(aParamBox,{1,"Data de ", aParam[03], "",'.T.',"" ,'.T.', 50, .T.})
	aAdd(aParamBox,{1,"Data ate", aParam[04], "",'empty(mv_par04).or.mv_par04>mv_par03',"" ,'.T.', 50, .T.})

	If ParamBox(aParamBox,"PARÂMETROS",@aParam) .and. aParam[04] > aParam[03]

        FWMsgRun(,{|| AtuVlrAcum(aParam)},"Aguarde","Reprocessando valores acumulados...")

    EndIf

Return

Static Function AtuVlrAcum(aParam)

    Local aArea := GetArea()
	Local aAreaMIE := MIE->(GetArea())
    Local dData := CtoD('')

    DbSelectArea("MIE")
    MIE->(DbSetOrder(1)) //MIE_FILIAL+MIE_CODPRO+DTOS(MIE_DATA)+MIE_CODTAN+MIE_CODBIC

    dData := aParam[03]
    While dData <= aParam[04]
        If MIE->(DbSeek( aParam[01] + aParam[02] + DTOS(dData) ))
            Reclock("MIE", .F.)
                MIE->MIE_VLRITE := MIE->MIE_VENDAS * MedPrecoVend(dData, aParam[02], aParam[01])
                MIE->MIE_ACUMUL := Acumulado(dData, aParam[02]) + MIE->MIE_VLRITE
            MIE->(MsUnlock())
        Else
            Exit
        EndIf
        dData := DaySum(dData,1)
    EndDo

    RestArea(aAreaMIE)
	RestArea(aArea)

Return 
