#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} STIPSTGRID
PE para manipular Grid de abastecimentos pendentes.

DANILO: 11/08/2021 - Descontinuado, pois ficará a escolha do cliente
utilizar ou não o ponto de entrada. 
Deixei um exemplo abaixo de como utilizar

@author Pablo
@since 25/10/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User function TPDVP011()
	Local cTipo  := ParamIxb[1] //1 cabeçalho / 2=itens listados
    Local aHead1 := ParamIxb[2]
Return aHead1

/*
#include 'protheus.ch'
#include 'parmtype.ch'

Static aPosDados := {} // utilizado para manipular posições no array de dados
Static __XVEZ := "0" 
Static __ASC  := .T.
Static nGridWnd := -1

User Function STIPSTGRID()

	Local cTipo  := ParamIxb[1] //1 cabeçalho / 2=itens listados
    Local aHead1 := ParamIxb[2]
	Local aArea		:= GetArea()
    Local aPstGrid := {}
    Local nPos := 0
    Local nX := 0

    if cTipo == 1 //Cabecalho
        aPosDados := {}

		//-- Montagem para Array da grid de abastecimentos
		//aPEPstGrid := { ;
		//	STDLegSupply(nCont) 01 Status,;
		//	aSupplyFuel[nCont][MIDCODBIC] 02 Bico,;
		//	MHZ->MHZ_DESPRO 03 Descricao produto,;
		//	aSupplyFuel[nCont][MIDHORACO] 04 Hora,;
		//	aSupplyFuel[nCont][MIDPREPLI] 05 Vlr Unit Combustivel,;
		//	aSupplyFuel[nCont][MIDLITABA] 06 Litros,;
		//	aSupplyFuel[nCont][MIDTOTAPA] 07 Vlr Abast,;
		//	aSupplyFuel[nCont][SA3NREDUZ] 08 Frentista,;
		//	aSupplyFuel[nCont][MIDDATACO] 09 Data,;
		//	aSupplyFuel[nCont][MIDPDV] 10 PDV ,;
		//	aSupplyFuel[nCont][MIDCODIGO] 11 Nr Abastecimento,;
		//	MHZ->MHZ_CODPRO 12 Cod Prod,;
		//	aSupplyFuel[nCont][MIDNUMORC] 13 Nr Orcamento,;
		//	aSupplyFuel[nCont][MIDTANQUE] 14 Nr Tanque,;
		//	aSupplyFuel[nCont][MIDBOMBA] 15 Nr Bomba,;
		//	aSupplyFuel[nCont][MIDENCINI] 16 Encerrante Inicial,;
		//	aSupplyFuel[nCont][MIDENCFIN] 17 Encerrante Final,;
		//	aSupplyFuel[nCont][MIDLEITUR] 18 Codigo unico de abastecimento,;
		//	aSupplyFuel[nCont][MIDAUDIT] 19 Abastecimento teve interverncao?,;
		//	aSupplyFuel[nCont][MIDPBIO] 20 % Biodiesel,;
		//	aSupplyFuel[nCont][MIDINDIMP] 21 Indic Import,;
		//	aSupplyFuel[nCont][MIDUFORIG] 22 UF Orig,;
		//	aSupplyFuel[nCont][MIDPORIG] 23 % UF Origem,;
		//	aSupplyFuel[nCont][MIDCODANP] 24 Codigo ANP;
		//}

        if (nPos := aScan(aHead1,{|x| AllTrim(x[02])=="MARK"})) > 0
			aAdd(aPstGrid,aHead1[nPos])
            aadd(aPosDados, nPos)
		endif
        if (nPos := aScan(aHead1,{|x| AllTrim(x[02])=="MID_CODBIC"})) > 0
			aAdd(aPstGrid,aHead1[nPos])
            aadd(aPosDados, nPos)
		endif
        if (nPos := aScan(aHead1,{|x| AllTrim(x[02])=="MHZ_DESPRO"})) > 0
			aAdd(aPstGrid,aHead1[nPos])
            aadd(aPosDados, nPos)
		endif
        if (nPos := aScan(aHead1,{|x| AllTrim(x[02])=="MID_PREPLI"})) > 0
			aAdd(aPstGrid,aHead1[nPos])
            aadd(aPosDados, nPos)
		endif
        if (nPos := aScan(aHead1,{|x| AllTrim(x[02])=="MID_LITABA"})) > 0
			aAdd(aPstGrid,aHead1[nPos])
            aadd(aPosDados, nPos)
		endif
        if (nPos := aScan(aHead1,{|x| AllTrim(x[02])=="MID_TOTAPA"})) > 0
			aAdd(aPstGrid,aHead1[nPos])
            aadd(aPosDados, nPos)
		endif
		if (nPos := aScan(aHead1,{|x| AllTrim(x[02])=="MID_HORACO"})) > 0
			aAdd(aPstGrid,aHead1[nPos])
            aadd(aPosDados, nPos)
		endif
        if (nPos := aScan(aHead1,{|x| AllTrim(x[02])=="A3_NREDUZ"})) > 0
			aAdd(aPstGrid,aHead1[nPos])
            aadd(aPosDados, nPos)
		endif
        if (nPos := aScan(aHead1,{|x| AllTrim(x[02])=="MID_DATACO"})) > 0
			aAdd(aPstGrid,aHead1[nPos])
            aadd(aPosDados, nPos)
		endif
        if (nPos := aScan(aHead1,{|x| AllTrim(x[02])=="MID_PDV"})) > 0
			aAdd(aPstGrid,aHead1[nPos])
            aadd(aPosDados, nPos)
		endif
        if (nPos := aScan(aHead1,{|x| AllTrim(x[02])=="MID_CODABA"})) > 0
			aAdd(aPstGrid,aHead1[nPos])
            aadd(aPosDados, nPos)
		endif
        if (nPos := aScan(aHead1,{|x| AllTrim(x[02])=="MHZ_CODPRO"})) > 0
			aAdd(aPstGrid,aHead1[nPos])
            aadd(aPosDados, nPos)
		endif
        if (nPos := aScan(aHead1,{|x| AllTrim(x[02])=="MID_NUMORC"})) > 0
			aAdd(aPstGrid,aHead1[nPos])
            aadd(aPosDados, nPos)
		endif
        if (nPos := aScan(aHead1,{|x| AllTrim(x[02])=="MID_CODTAN"})) > 0
			aAdd(aPstGrid,aHead1[nPos])
            aadd(aPosDados, nPos)
		endif
        if (nPos := aScan(aHead1,{|x| AllTrim(x[02])=="MID_CODBOM"})) > 0
			aAdd(aPstGrid,aHead1[nPos])
            aadd(aPosDados, nPos)
		endif
        if (nPos := aScan(aHead1,{|x| AllTrim(x[02])=="MID_ENCFIN"})) > 0
			aAdd(aPstGrid,aHead1[nPos])
            aadd(aPosDados, nPos)
		endif
        if (nPos := aScan(aHead1,{|x| AllTrim(x[02])=="MID_ENCINI"})) > 0
			aAdd(aPstGrid,aHead1[nPos])
            aadd(aPosDados, nPos)
		endif
        if (nPos := aScan(aHead1,{|x| AllTrim(x[02])=="MID_LEITUR"})) > 0
			aAdd(aPstGrid,aHead1[nPos])
            aadd(aPosDados, nPos)
		endif

        //campos nao listados acima, incluo no fim
        for nX := 1 to Len(aHead1)
			if (nPos := aScan(aPstGrid,{|x| AllTrim(x[02])==aHead1[nX][02]})) <= 0
				aAdd(aPstGrid,aHead1[nX])
                aadd(aPosDados, nX)
			endif
		next nX

    else //se tipo = 2, dados, ajusto a ordem dos campos
		
        if len(aPosDados) > 0
            
            for nX := 1 to len(aPosDados)
                aadd(aPstGrid, aHead1[ aPosDados[nX] ])
            next nX
            
        else //segurança se der algum BO
            aPstGrid := aHead1
        endif

        //adiciono funcionalidade de ordenacao no grid, pelo header
        oGetList := STIGGridAbast() //pega o grid de abastecimentos
		if Valtype(oGetList) == "O" .AND. oGetList:oBrowse:hWnd <> nGridWnd
            oGetList:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(STIGGridAbast(), @nCol), )}
            nGridWnd := oGetList:oBrowse:hWnd
        endif
    endif

	RestArea(aArea)

Return aPstGrid

//--------------------------------------------------------------------------------------
// Função para ordenaçao de grid MsNewGetDados
//--------------------------------------------------------------------------------------
Static Function OrdGrid(oObj, nColum)

	if __XVEZ == "0"
		__XVEZ := "1"
	else
		if __XVEZ == "1"
			__XVEZ := "2"
		endif
	endif

	if __XVEZ == "2"

		// reordeno o array do grid
		if __ASC
			if valtype(oObj) == "A"
				ASORT(oObj,,,{|x, y| x[nColum] < y[nColum] }) //ordena?o crescente
			else
				ASORT(oObj:aCols,,,{|x, y| x[nColum] < y[nColum] }) //ordena?o crescente
			endif
			__ASC := .F.
		else
			if valtype(oObj) == "A"
				ASORT(oObj,,,{|x, y| x[nColum] > y[nColum] }) //ordena?o decrescente
			else
				ASORT(oObj:aCols,,,{|x, y| x[nColum] > y[nColum] }) //ordena?o decrescente
			endif
			__ASC := .T.
		endif

		// fa? um refresh no grid
		if valtype(oObj) == "O"
			oObj:oBrowse:Refresh()
		endif
		__XVEZ := "0"

	endif

Return()
