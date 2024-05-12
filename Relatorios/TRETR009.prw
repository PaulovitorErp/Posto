#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"
#INCLUDE "TOTVS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "Shell.ch"
#INCLUDE "FWPRINTSETUP.CH"
#INCLUDE "PROTHEUS.CH"

#define DMPAPER_A4 9    // A4 210 x 297 mm

/*/{Protheus.doc} TRETR009
Impressão Boleto Bancário
@author Totvs TBC
@since 26/04/2019
@version 1.0
@return ${return}, ${return_description}
@param _Exec,_cDef2Printer,lEnvMail,lMo,lImprime,aArqPDF

E1_MULTA  = Vlr. da multa a cerca do recebimento
E1_JUROS  = Vlr. da taxa permanencia cobrada
E1_CORREC = vlr. da Correcao referente ao recebimento
E1_VALJUR = Taxa diaria, tem precedencia ao % juros
E1_PORCJUR = % juro atraso dia

Campos que devem ser criados
E1_DVNSNUM = C = 1
EE_XCART = C = 3
EE_XDVCTA = C = 1
EE_XDVAGE = C = 1

EE_TIPODAT = Mudar para 4 a data para baixa sair correta

MV_TXPER = Indique o % da Taxa de Juros e colocado no E1_PORCJUR, ele ira calcular o E1_VALJUR
MV_LJMULTA = Percentual de multa para os titulos em atraso. Utilizado na rotina de recebimento de titulos.
/*/
User Function TRETR009(_Exec,_cDef2Printer,lEnvMail,lMo,lImprime,aArqPDF,_cFilial)

	Local _cQry := ""

	Default lMo			:= .F.
	Default lImprime 	:= .T.
	Default _cFilial	:= "0101" 

	Private lRet		:= .T.

	Private _lImprime	:= lImprime
	Private lJob		:= .F.

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Preparo o ambiente na qual sera executada a rotina de negocio      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If Select("SX2") == 0 // Se via JOB
		lJob := .T.
		//conout(DTOC(DATE())+"-"+Time()+" Iniciando rotina para emissão de boletos...")

		PREPARE ENVIRONMENT EMPRESA "01" FILIAL _cFilial TABLES "SA3","SED","SEE","SE1","SEA"
	Else
		DbSelectArea("SA3")
		DbSelectArea("SED")
		DbSelectArea("SEE")
		DbSelectArea("SE1")
		DbSelectArea("SEA")
	EndIf

	Private lExec		:= .F.
	Private cIndexName	:= ''
	Private cIndexKey  	:= ''
	Private cFilter    	:= ''
	Private cNumBco    	:= ''
	Private cMarca     	:= GetMark()
	Private Tamanho  	:= "M"
	Private titulo   	:= "Impressao de Boleto com Codigo de Barras"
	Private cDesc1   	:= "Este programa destina-se a impressao do Boleto com Codigo de Barras."
	Private cDesc2   	:= ""
	Private cDesc3   	:= ""
	Private cString  	:= "SE1"
	Private wnrel    	:= "BOLETO LASER"
	Private lEnd     	:= .F.
	Private cPerg     	:= Padr("RFIN001",10)
	Private aReturn  	:= {"Zebrado", 1,"Administracao", 2, 2, 1, "",1 }
	Private nLastKey 	:= 0
	Private aCampos 	:={}
	Private _MsExec		:= .F.
	Private cDigAg		:= ""
	Private cDigConta	:= ""

	Private oTempTable as object
	Private cAliasTemp as char
	
	Private lMarajo		:= SuperGetMv("MV_XMARAJO",.F.,.F.)

	DEFAULT _Exec := {}

	_MsExec	:= Len(_Exec) > 0

	AjustaSx1(cPerg)

	if _MsExec
		Pergunte(cPerg,.F.)
	elseif !Pergunte(cPerg,.T.)
		Return
	endif

	If LastKey() == 27
		Return

	ElseIf Len(_Exec) <> 22 .and. _MsExec

		If !IsBlind()
			Aviso("ERRO","Informar ao Dept. T.I. diferença nos parametros vindo do Faturamento.",{"OK"})
		Else
			//conout("Informar ao Dept. T.I. diferença nos parametros vindo do Faturamento.")
		EndIf

		Return

	ElseIf _MsExec

		MV_PAR01 := _Exec[01]	// Prefixo
		MV_PAR02 := _Exec[02]
		MV_PAR03 := _Exec[03]	// Nr.
		MV_PAR04 := _Exec[04]
		MV_PAR05 := _Exec[05]	// Parcela
		MV_PAR06 := _Exec[06]
		MV_PAR07 := _Exec[07]	// Portador
		MV_PAR08 := _Exec[08]
		MV_PAR09 := _Exec[09]	// Cliente
		MV_PAR10 := _Exec[10]
		MV_PAR11 := _Exec[11]	// Loja
		MV_PAR12 := _Exec[12]
		MV_PAR13 := _Exec[13]	// Emissão
		MV_PAR14 := _Exec[14]
		MV_PAR15 := _Exec[15]	// Vencimento
		MV_PAR16 := _Exec[16]
		MV_PAR17 := _Exec[17]	// Nr. Bordero
		MV_PAR18 := _Exec[18]
		MV_PAR19 := _Exec[19]	// Nr. Carga
		MV_PAR20 := _Exec[20]
		MV_PAR21 := _Exec[21]	// Msg1
		MV_PAR22 := _Exec[22]	// Msg2
	EndIf

	_cQry := ""
	_cQry += " SELECT DISTINCT"
	_cQry += "    (SELECT "
	_cQry += "       SUM(E1_VLCRUZ) "
	_cQry += "     FROM "
	_cQry += "          "+RetSqlName("SE1")
	_cQry += "     WHERE "
	_cQry += "           D_E_L_E_T_ = ' ' "
	_cQry += "       AND LTRIM(RTRIM(E1_TIPO)) = 'NCC'  "
	_cQry += "       AND E1_CLIENTE = SE1.E1_CLIENTE  "
	_cQry += "       AND E1_LOJA    = SE1.E1_LOJA "
	_cQry += "     ) E1_NCC "
	_cQry += "   ,(SELECT  "
	_cQry += "       SUM(E1_VLCRUZ) "
	_cQry += "     FROM "
	_cQry += "          "+RetSqlName("SE1")
	_cQry += "     WHERE "
	_cQry += "           D_E_L_E_T_ = ' ' "
	_cQry += "       AND LTRIM(RTRIM(E1_TIPO)) = 'RA'  "
	_cQry += "       AND E1_CLIENTE = SE1.E1_CLIENTE "
	_cQry += "       AND E1_LOJA    = SE1.E1_LOJA "
	_cQry += "     ) E1_RA "
	_cQry += "   ,'  ' AS E1_OK "
	_cQry += "   ,SE1.E1_TIPO "
	_cQry += "   ,F2_CARGA E1_CARGA "
	_cQry += "   ,E1_NUMBOR   "
	_cQry += "   ,E1_PREFIXO   "
	_cQry += "   ,E1_NUM "
	_cQry += "   ,E1_PARCELA "
	_cQry += "   ,E1_TIPO "
	_cQry += "   ,E1_NATUREZ  "
	_cQry += "   ,E1_PORTADO  "
	_cQry += "   ,E1_CLIENTE "
	_cQry += "   ,A1_NOME E1_NOME"
	_cQry += "   ,E1_LOJA  "
	_cQry += "   ,E1_EMISSAO "
	_cQry += "   ,E1_VENCTO  "
	_cQry += "   ,E1_VENCREA "
	_cQry += "   ,E1_VLCRUZ  "
	_cQry += "   ,E1_FILIAL  "
	_cQry += "   ,E1_VEND1 "
	_cQry += "   ,E1_SALDO "
	_cQry += "   ,E1_HIST "
	_cQry += "   ,E1_SDDECRE "
	_cQry += "   ,E1_DESCFIN "
	_cQry += "   ,E1_ACRESC "
	_cQry += "   ,E1_DECRESC "
	_cQry += "   ,E1_VALOR "
	_cQry += " FROM "
	_cQry += "    "+RetSqlName("SE1")+" SE1 "

// Nota fiscal de saida
	_cQry += "    LEFT OUTER JOIN "+RetSqlName("SF2")+" SF2 "
	_cQry += "    ON    SE1.E1_FILIAL  = SF2.F2_FILIAL "
	_cQry += "      AND SE1.E1_NUM     = SF2.F2_DOC  "
	_cQry += "      AND SE1.E1_PREFIXO = SF2.F2_SERIE "
	_cQry += "      AND SE1.E1_CLIENTE = SF2.F2_CLIENTE "
	_cQry += "      AND SE1.E1_LOJA    = SF2.F2_LOJA "
	_cQry += "      AND SF2.D_E_L_E_T_ = ' ' "

// Tabela de borderô
	_cQry += "    LEFT OUTER JOIN "+RetSqlName("SEA")+" SEA "
	_cQry += "    ON    SE1.E1_FILIAL  = SEA.EA_FILIAL "
	_cQry += "      AND SE1.E1_NUM     = SEA.EA_NUM  "
	_cQry += "      AND SE1.E1_PREFIXO = SEA.EA_PREFIXO "
	_cQry += "      AND SE1.E1_PARCELA = SEA.EA_PARCELA "

	_cQry += "   ,"+RetSqlName("SA1")+" SA1 "
	_cQry += " WHERE "
	_cQry += 	"     SE1.D_E_L_E_T_ = ' ' "
	_cQry += 	" AND SA1.A1_COD     = SE1.E1_CLIENTE "
	_cQry += 	" AND SA1.A1_LOJA    = SE1.E1_LOJA "
	_cQry += 	" AND LTRIM(RTRIM(SE1.E1_TIPO))  NOT IN ('NCC','RA','TX')  "
	_cQry += 	" AND E1_FILIAL           = '"+xFilial("SE1") + "'
	_cQry += 	" AND E1_PREFIXO BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "' "
	_cQry += 	" AND E1_NUM     BETWEEN '" + MV_PAR03 + "' AND '" + MV_PAR04 + "' "
	_cQry += 	" AND E1_PARCELA BETWEEN '" + MV_PAR05 + "' AND '" + MV_PAR06 + "' "
//_cQry += 	" AND E1_PORTADO BETWEEN '" + MV_PAR07 + "' AND '" + MV_PAR08 + "' "
	_cQry += 	" AND E1_CLIENTE BETWEEN '" + MV_PAR09 + "' AND '" + MV_PAR10 + "' "
	_cQry += 	" AND E1_LOJA    BETWEEN '" + MV_PAR11 + "' AND '" + MV_PAR12 + "' "

	If !Empty( AllTrim(MV_PAR19) )
		_cQry += " AND SF2.F2_CARGA BETWEEN '" + MV_PAR19+ "' AND '"+ MV_PAR20 + "' "
	EndIf

	If !Empty(MV_PAR17)
		_cQry += 	"   AND E1_NUMBOR BETWEEN '" + MV_PAR17 + "' AND '" + MV_PAR18 + "' "
	EndIf

	If (MV_PAR13 <> CTOD("  /  /    ")) .AND. (MV_PAR14 <> CTOD("  /  /    "))
		_cQry += " AND E1_EMISSAO BETWEEN '"+DTOS(MV_PAR13)+"' AND '"+DTOS(MV_PAR14)+"' "
	EndIf

	If (MV_PAR15 <> CTOD("  /  /    ")) .AND. (MV_PAR16 <> CTOD("  /  /    "))
		_cQry += " AND E1_VENCREA BETWEEN '"+DTOS(MV_PAR15)+"' AND '"+DTOS(MV_PAR16)+"' "
	EndIf

	_cQry += " AND E1_SALDO > 0 AND E1_TIPO NOT IN ('CF-','CS-','IN-','IR-','PI-','IS-') "
	_cQry += " ORDER BY E1_PREFIXO,E1_NUM,E1_PARCELA "

	_cQry := ChangeQuery(_cQry)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Abrir a Query ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aCampos := {}
	AAdd(aCampos,{ "E1_OK"		   	,"C",02,0 })
	AAdd(aCampos,{ "E1_EMISSAO" 	,"D",08,0 })
	AAdd(aCampos,{ "E1_PREFIXO"		,"C",len(SE1->E1_PREFIXO),0})
	AAdd(aCampos,{ "E1_NUM"			,"C",len(SE1->E1_NUM),0 })
	AAdd(aCampos,{ "E1_PARCELA"		,"C",len(SE1->E1_PARCELA),0 })
	AAdd(aCampos,{ "E1_CLIENTE"		,"C",len(SE1->E1_CLIENTE),0 })
	AAdd(aCampos,{ "E1_LOJA"  		,"C",len(SE1->E1_LOJA),0 })
	AAdd(aCampos,{ "E1_NOME"		,"C",40,0 })
	AAdd(aCampos,{ "E1_VENCTO" 		,"D",08,0 })
	AAdd(aCampos,{ "E1_VENCREA"		,"D",08,0 })
	AAdd(aCampos,{ "E1_VLCRUZ"		,"N",15,2 })
	AAdd(aCampos,{ "E1_SALDO"		,"N",15,2 })
	AAdd(aCampos,{ "E1_ACRESC"		,"N",15,2 })
	AAdd(aCampos,{ "E1_NCC"	      	,"N",12,2 })
	AAdd(aCampos,{ "E1_RA"	      	,"N",12,2 })
	AAdd(aCampos,{ "E1_CARGA"		,"C",06,0})
	AAdd(aCampos,{ "E1_NUMBOR"		,"C",06,0})
	AAdd(aCampos,{ "E1_TIPO"		,"C",03,0})
	AAdd(aCampos,{ "E1_NATUREZ"		,"C",10,0 })
	AAdd(aCampos,{ "E1_PORTADO"		,"C",03,0})
	AAdd(aCampos,{ "E1_FILIAL"	   	,"C",03,0 })
	AAdd(aCampos,{ "E1_VEND1"	   	,"C",06,0 })
	AAdd(aCampos,{ "E1_DESCFIN"		,"N",06,2 })
	AAdd(aCampos,{ "E1_DECRESC"		,"N",15,2 })
	AAdd(aCampos,{ "E1_VALOR"		,"N",15,2 })
	AAdd(aCampos,{ "E1_HIST"		,"C",25,0 })

	//cria a tabela temporaria
	oTempTable := FWTemporaryTable():New( /*cAlias*/, /*aFields*/)
	oTempTable:SetFields(aCampos)
	oTempTable:AddIndex("01", {"E1_FILIAL","E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO"} )
	oTempTable:Create()
	cAliasTemp := oTempTable:GetAlias()
	SQLToTrb(_cQry, aCampos, cAliasTemp) // Preenche um arquivo temporário com o conteúdo do retorno da query.
	DbSelectArea(cAliasTemp)
	(cAliasTemp)->(DbGoTop())

	cMarca := GetMark()
	cMarca := Soma1(cMarca)

	aStruSE1	:= {{"E1_OK" 		,""					,02,0},;
		{"E1_EMISSAO" 	,"Dt. Emissão"		,08,0},;
		{"E1_PREFIXO" 	,"Prefixo"			,Len(SE1->E1_PREFIXO),0},;
		{"E1_NUM" 		,"Titulo"			,Len(SE1->E1_NUM),0},;
		{"E1_PARCELA" 	,"Parcela"			,Len(SE1->E1_PARCELA),0},;
		{"E1_CLIENTE" 	,"Cliente"			,Len(SE1->E1_CLIENTE),0},;
		{"E1_LOJA" 		,"Loja"				,Len(SE1->E1_LOJA),0},;
		{"E1_NOME" 		,"Nome"				,40,0},;
		{"E1_VENCTO" 	,"Dt. Vencto"		,08,0},;
		{"E1_VENCREA"	,"Dt. Vencto Real"	,08,0},;
		{"E1_VLCRUZ"	,"Valor"			,"@E 999,999,999,999.99"},;
		{"E1_RA" 		,"RA"				,"@E 999,999,999.99"},;
		{"E1_NCC" 		,"NCC"				,"@E 999,999,999.99"},;
		{"E1_TIPO" 		,"Tipo"				,03,0},;
		{"E1_CARGA" 	,"Carga"			,06,0},;
		{"E1_NUMBOR" 	,"Bordero"			,06,0},;
		{"E1_NATUREZ" 	,"Natureza"			,10,0},;
		{"E1_VEND1" 	,"Vendedor"			,06,0},;
		{"E1_PORTADO" 	,"Portado"			,03,0}}

	(cAliasTemp)->(DbGoTop())

	If !_MsExec

		@ 001,001 TO 400,700 DIALOG oDlg TITLE "Seleção de Titulos"
		@ 001,001 TO 170,350 BROWSE cAliasTemp FIELDS aStruSE1 MARK "E1_OK" Object oBrowIncPed

		oBtn1 := TButton():New(180,050,"Desmarca Todos   " ,oDlg,{|| fMarTudo(cMarca,.t.)},060,015,,,,.T.)
		oBtn2 := TButton():New(180,110,"Marca Todos      " ,oDlg,{|| fMarTudo(cMarca,.f.)},060,015,,,,.T.)
		oBtn3 := TButton():New(180,170,"Inverte Seleção  " ,oDlg,{|| fMarTudo(cMarca,nil)},060,015,,,,.T.)
		oBtn4 := TButton():New(180,230,"Imprimir Boletos " ,oDlg,{|| lExec := .T.,MontaRel(),Close(oDlg)},060,015,,,,.T.)
		oBtn4 := TButton():New(180,290,"Cancelar     	 " ,oDlg,{|| lExec := .F.,Close(oDlg)},060,015,,,,.T.)

		ACTIVATE DIALOG oDlg CENTERED
	Else
		lExec := .T.
		fMarTudo(cMarca,.F.)
		MontaRel(_cDef2Printer,lEnvMail,lMo)
	EndIf

	(cAliasTemp)->(DbCloseArea())
	oTempTable:Delete()

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} fMarTudo
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function fMarTudo(cMarca,ltudo)

	Local aArea := (cAliasTemp)->(GetArea())

	(cAliasTemp)->(DbGoTop())

	While !(cAliasTemp)->(Eof())

		RecLock(cAliasTemp,.F.)

		If lTudo        // Marca todos os Itens
			(cAliasTemp)->E1_OK := cMarca
		ElseIf !lTudo   // Desmarca todos os itens
			(cAliasTemp)->E1_OK := "  "
		Else             // Inverte a Seleção
			If (cAliasTemp)->E1_OK == cMarca
				(cAliasTemp)->E1_OK := "  "
			Else
				(cAliasTemp)->E1_OK := cMarca
			EndIf
		EndIf

		(cAliasTemp)->(MsUnLock())
		(cAliasTemp)->(DbSkip())
	Enddo

	RestArea(aArea)

	If !_MsExec
		oDlg:Refresh()
	EndIf

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} MontaRel
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function MontaRel(_cDef2Printer,lEnvMail,lMo)
	ImpDet(_cDef2Printer,lEnvMail,lMo)
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} ImpDet
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function ImpDet(_cDef2Printer,lEnvMail,lMo)

	Local nX      		:= 0
	Local lAchou 		:= .F.
	Local aDadosEmp		:= {SM0->M0_NOMECOM                                    							,; //[1]Nome da Empresa
	SM0->M0_ENDCOB                                     							,; //[2]Endereço
	AllTrim(SM0->M0_BAIRCOB)+", "+AllTrim(SM0->M0_CIDCOB)+", "+SM0->M0_ESTCOB	,; //[3]Complemento
	"CEP: "+Subs(SM0->M0_CEPCOB,1,5)+"-"+Subs(SM0->M0_CEPCOB,6,3)				,; //[4]CEP
	"PABX/FAX: "+SM0->M0_TEL													,; //[5]Telefones
	"CNPJ: "+Subs(SM0->M0_CGC,1,2)+"."+Subs(SM0->M0_CGC,3,3)+"."+				;  //[6] CGC
	Subs(SM0->M0_CGC,6,3)+"/"+Subs(SM0->M0_CGC,9,4)+"-"+						;  //[6]
	Subs(SM0->M0_CGC,13,2)														,; //[6]
	"I.E.: "+Subs(SM0->M0_INSC,1,3)+"."+Subs(SM0->M0_INSC,4,3)+"."+				;  //[7]I.E
	Subs(SM0->M0_INSC,7,3)+"."+Subs(SM0->M0_INSC,10,3)}  						   //[7]

	Local aDadosTit
	Local aDadosBanco
	Local aDatSacado
	Local aBolText		:= {SuperGetMv("MV_MENBOL1",,"  ")   ,; // Primeiro texto para comentario
	SuperGetMv("MV_MENBOL2",,"  ")   ,; // Segundo texto para comentario
	SuperGetMv("MV_MENBOL3",,"  ")   ,; // Terceiro texto para comentario
	" ",;
		" ",;
		" ",;
		" "}

	Local nI			:= 1
	Local aCB_RN_NN		:= {}
	Local nVlrAbat		:= 0

	Local nDiasProt		:= SuperGetMv("MV_XDIASPR",.F.,10) // Dias para protesto
	Local aAreaSe1      := {} //atender API
	Local aParApi	  	:= {} //atender API

	Local nMVTXPER		:= GetMV("MV_TXPER")
	Local nMVMULTA		:= GetMV("MV_LJMULTA")
	Local lPe009API		:= ExistBlock("TR009API")
	Local bGetMvFil	:= {|cParametro,lHelp,cDefault,cFil| SuperGetMV(cParametro,lHelp,cDefault,cFil) }

	Private _cConvenio	:= ""
	Private _cCarteira	:= ""

	Private cString		:= "SE1"
	Private wnrel		:= "BOLETO BANCARIO"
	Private titulo		:= "Impressao de Boleto com Codigo de Barras"
	Private cDesc1		:= "Este programa destina-se a impressao do Boleto com Codigo de Barras."
	Private cDesc2		:= ""
	Private cDesc3		:= ""
	Private Tamanho		:= "G"

	Private aReturn		:= {"Zebrado", 1,"Administracao", 2, 2, 1, "",1 }
	Private nLastKey	:= 0

	if nMVTXPER == 0
		nMVTXPER		:= SuperGetMV("MV_XTXPER",.F.,0)
	endif

	If nLastKey == 27
		Set Filter to
		Return
	EndIf

	lEntPeloMenosVez := .F.

	(cAliasTemp)->(DbGoTop())

	While !(cAliasTemp)->(Eof())

		If !IsBlind()
			ProcessMessages()
		EndIf

		If (cAliasTemp)->E1_OK = '  '

			lEntPeloMenosVez := .T.
			SE1->(DbSetOrder(2)) //E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO

			If SE1->(DbSeek(xFilial("SE1") + (cAliasTemp)->E1_CLIENTE + (cAliasTemp)->E1_LOJA + (cAliasTemp)->E1_PREFIXO + (cAliasTemp)->E1_NUM + (cAliasTemp)->E1_PARCELA + (cAliasTemp)->E1_TIPO))

				cNroDoc    :=  ""

				If !NrBordero()

					Set Filter to

					Return
				EndIf

				// Posiciona no Borderô
				SEA->(DbSetOrder(1)) //EA_FILIAL+EA_NUMBOR+EA_PREFIXO+EA_NUM+EA_PARCELA+EA_TIPO+EA_FORNECE+EA_LOJA
				If !SEA->(DbSeek(xFilial("SEA") + SE1->E1_NUMBOR + (cAliasTemp)->E1_PREFIXO + (cAliasTemp)->E1_NUM + (cAliasTemp)->E1_PARCELA + (cAliasTemp)->E1_TIPO))

					If !IsBlind()
						Alert("Titulo nao localizado no bordero selecionado. Pref. "+Alltrim((cAliasTemp)->E1_PREFIXO)+" Tit. "+Alltrim((cAliasTemp)->E1_NUM))
					Else
						//conout("Titulo nao localizado no bordero selecionado. Pref. "+Alltrim((cAliasTemp)->E1_PREFIXO)+" Tit. "+Alltrim((cAliasTemp)->E1_NUM))
					EndIf

					Return
				EndIf

				// Posiciona nos Parâmetros de Bancos
				SEE->(DbSetOrder(1)) //EE_FILIAL+EE_CODIGO+EE_AGENCIA+EE_CONTA+EE_SUBCTA
				If !SEE->(DbSeek(xFilial("SEE")+SEA->(EA_PORTADO+EA_AGEDEP+EA_NUMCON)+"001",.T.))

					If !IsBlind()
						Alert("Erro na leitura dos parametros do banco do bordero gerado (Sub-conta diferente de 001),")
					Else
						//conout("Erro na leitura dos parametros do banco do bordero gerado (Sub-conta diferente de 001)")
					EndIf

					Return
				EndIf

				//Posiciona na SA6 (Bancos)
				SA6->(DbSetOrder(1)) //A6_FILIAL+A6_COD+A6_AGENCIA+A6_NUMCON
				If !SA6->(DbSeek(xFilial("SA6")+SEA->(EA_PORTADO+EA_AGEDEP+EA_NUMCON) ,.T.))

					If !IsBlind()
						Alert("Banco do bordero ("+Alltrim(SEA->EA_PORTADO)+" - "+Alltrim(SEA->EA_AGEDEP)+" - "+Alltrim(SEA->EA_NUMCON)+") nao localizado no cadastro de Bancos.")
					Else
						//conout("Banco do bordero ("+Alltrim(SEA->EA_PORTADO)+" - "+Alltrim(SEA->EA_AGEDEP)+" - "+Alltrim(SEA->EA_NUMCON)+") nao localizado no cadastro de Bancos.")
					EndIf

					Return
				EndIf

				If !(SEE->EE_CODIGO $ '422/341') .AND. Empty(SEE->EE_CODEMP)

					If !IsBlind()
						Alert("Informar o convenio do banco no cadastro de parametros do banco (EE_CODEMP) !")
					Else
						//conout("Informar o convenio do banco no cadastro de parametros do banco (EE_CODEMP) !")
					EndIf

					Return
				EndIf

				If Empty(SEE->EE_TABELA)

					If !IsBlind()
						Alert("Informar a tabela do banco no cadastro de parametros do banco (EE_TABELA) !")
					Else
						//conout("Informar a tabela do banco no cadastro de parametros do banco (EE_TABELA) !")
					EndIf

					Return
				EndIf

				_cConvenio	:= AllTrim(SEE->EE_CODEMP)
				_cCarteira	:= AllTrim(SEE->EE_CODCART)
				cDigAg 		:= AllTrim(SEE->EE_DVAGE)
				cDigConta	:= AllTrim(SEE->EE_DVCTA)

				//Posiciona o SA1 (Cliente)
				SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
				SA1->(DbSeek(xFilial("SA1")+(cAliasTemp)->E1_CLIENTE+(cAliasTemp)->E1_LOJA,.T.))

				If SEE->EE_CODIGO == '001' // Banco do Brasil

					aDadosBanco := {SEE->EE_CODIGO          ,;												// [1]Numero do Banco
					"BANCO BRASIL S.A"     ,; 												// [2]Nome do Banco
					Substr(SEE->EE_AGENCIA,1,4)   ,;										// [3]Agência
					Alltrim(SEE->EE_CONTA),; 												// [4]Conta Corrente -2
					Alltrim(SEE->EE_DVCTA),; 												// [5]Dígito da conta corrente
					_cCarteira ,; 															// [6]Codigo da Carteira
					"9" ,; 																	// [7] Digito do Banco
					"Pagável em qualquer banco até o vencimento" ,; 						// [8] Local de Pagamento1
					" ",; 																	// [9] Local de Pagamento2
					SEE->EE_DVAGE,; 														//[10] Digito Verificador da agencia
					_cConvenio,;     														//[11] Código Cedente fornecido pelo Banco
					iif( SEE->(FieldPos("EE_XCODEMP"))>0,SEE->EE_XCODEMP, SEE->EE_CODEMP) }	//[12] Código Cedente fornecido pelo Banco

				ElseIf SEE->EE_CODIGO == '341' // Itaú

					aDadosBanco := {SEE->EE_CODIGO          ,;												// [1]Numero do Banco
					"Banco Itaú S.A."     ,; 												// [2]Nome do Banco
					Substr(SEE->EE_AGENCIA,1,4)   ,;										// [3]Agência
					Alltrim(SEE->EE_CONTA),; 												// [4]Conta Corrente -2
					Alltrim(SEE->EE_DVCTA),; 												// [5]Dígito da conta corrente
					_cCarteira ,; 															// [6]Codigo da Carteira
					"7" ,; 																	// [7] Digito do Banco
					"Até o vencimento, pague preferencialmente no Itaú." ,; 				// [8] Local de Pagamento1
					"Após o vencimento, pague somente no Itaú.",; 							// [9] Local de Pagamento2
					SEE->EE_DVAGE,;															//[10] Digito Verificador da agencia
					_cConvenio}																//[11] Código Cedente fornecido pelo Banco

				ElseIf SEE->EE_CODIGO == '422' // Safra

					aDadosBanco := {SEE->EE_CODIGO          ,;												// [1]Numero do Banco
					"Banco Safra S.A."     ,; 																// [2]Nome do Banco
					Substr(SEE->EE_AGENCIA,1,4)   ,;														// [3]Agência
					Alltrim(SEE->EE_CONTA),; 																// [4]Conta Corrente -2
					Alltrim(SEE->EE_DVCTA),; 																// [5]Dígito da conta corrente
					_cCarteira ,; 																			// [6]Codigo da Carteira
					"7" ,; 																					// [7] Digito do Banco
					"Até o vencimento, pague preferencialmente no Safra." ,; 								// [8] Local de Pagamento1
					" ",; 																					// [9] Local de Pagamento2
					SEE->EE_DVAGE,;																			//[10] Digito Verificador da agencia
					_cConvenio}																				//[11] Código Cedente fornecido pelo Banco


				ElseIf SEE->EE_CODIGO == '237' // Bradesco

					aDadosBanco := {SEE->EE_CODIGO          ,;												// [1]Numero do Banco
					"BRADESCO S.A."     ,; 													// [2]Nome do Banco
					Substr(SEE->EE_AGENCIA,1,4)   ,;										// [3]Agência
					Alltrim(SEE->EE_CONTA),; 												// [4]Conta Corrente -2
					Alltrim(SEE->EE_DVCTA),; 												// [5]Dígito da conta corrente
					_cCarteira ,; 															// [6]Codigo da Carteira
					"2" ,; 																	// [7] Digito do Banco
					"Até o vencimento, preferencialmente nas agências bradesco ou bradesco expresso" ,; // [8] Local de Pagamento1
					"Após o vencimento, nas agências do bradesco",; 						// [9] Local de Pagamento2
					SEE->EE_DVAGE,;															//[10] Digito Verificador da agencia
					_cConvenio}																//[11] Código Cedente fornecido pelo Banco

				ElseIf SEE->EE_CODIGO == '033' // Santander

					aDadosBanco := {SEE->EE_CODIGO          	,;											// [1]Numero do Banco
					"SANTANDER S.A."     		,; 											// [2]Nome do Banco
					AllTrim(SEE->EE_AGENCIA)   ,;											// [3]Agência
					Alltrim(SEE->EE_CONTA),; 												// [4]Conta Corrente -2
					Alltrim(SEE->EE_DVCTA),; 												// [5]Dígito da conta corrente ( e para ser vazio )
					"101"/*_cCarteira*/ ,; 													// [6]Codigo da Carteira
					"7" ,; 																	// [7] Digito do Banco
					"PAGAR PREFERENCIALMENTE NO GRUPO SANTANDER - GC" ,; 					// [8] Local de Pagamento1
					""/*"APÓS O VENCIMENTO, SOMENTE NAS AGÊNCIAS DO SANTANDER"*/,; 			// [9] Local de Pagamento2
					SEE->EE_DVAGE,;															//[10] Digito Verificador da agencia
					_cConvenio}																//[11] Código Cedente fornecido pelo Banco

				ElseIf SEE->EE_CODIGO == '756'  // Banco Sicoob

					aDadosBanco := {SEE->EE_CODIGO          ,;												// [1]Numero do Banco
					"SICOOB"     ,; 														// [2]Nome do Banco
					AllTrim(SubStr(SEE->EE_AGENCIA,1,4)) ,;									// [3]Agência
					AllTrim(SEE->EE_CONTA),; 												// [4]Conta Corrente -2
					AllTrim(SEE->EE_DVCTA),; 												// [5]Dígito da conta corrente
					_cCarteira ,; 															// [6]Codigo da Carteira
					"0" ,; 																	// [7] Digito do Banco
					"Pagável em qualquer banco até a data de vencimento." ,; 				// [8] Local de Pagamento1
					"",; 																	// [9] Local de Pagamento2
					"",; 																	//[10] Digito Verificador da agencia
					_cConvenio}																//[11] Código Cedente fornecido pelo Banco
				EndIf

				If Empty(SA1->A1_ENDCOB)

					aDatSacado := {AllTrim(SA1->A1_NOME)           ,;      									// [1]Razão Social
					AllTrim(SA1->A1_COD )+"-"+SA1->A1_LOJA           ,;      				// [2]Código
					AllTrim(SA1->A1_END )+"-"+AllTrim(SA1->A1_BAIRRO),;      				// [3]Endereço
					AllTrim(SA1->A1_MUN )                            ,;  					// [4]Cidade
					SA1->A1_EST                                      ,;     				// [5]Estado
					SA1->A1_CEP                                      ,;      				// [6]CEP
					SA1->A1_CGC										 ,;  					// [7]CGC
					SA1->A1_PESSOA									  }     				// [8]PESSOA
				Else

					aDatSacado := {AllTrim(SA1->A1_NOME)            	,;   								// [1]Razão Social
					AllTrim(SA1->A1_COD )+"-"+SA1->A1_LOJA              ,;   				// [2]Código
					AllTrim(SA1->A1_ENDCOB)+"-"+AllTrim(SA1->A1_BAIRROC),;   				// [3]Endereço
					AllTrim(SA1->A1_MUN )	                            ,;   				// [4]Cidade
					SA1->A1_ESTC	                                    ,;   				// [5]Estado
					SA1->A1_CEPC                                        ,;   				// [6]CEP
					SA1->A1_CGC											,;					// [7]CGC
					SA1->A1_PESSOA										 }					// [8]PESSOA
				EndIf

				nVlrAbat := SomaAbat((cAliasTemp)->E1_PREFIXO,(cAliasTemp)->E1_NUM,(cAliasTemp)->E1_PARCELA,"R",1,,(cAliasTemp)->E1_CLIENTE,(cAliasTemp)->E1_LOJA)

				// Incrementa sequencia do nosso numero no parametro banco
				_cont := 0

				DbSelectArea("SE1")
				SE1->(DbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO

				If SE1->(DbSeek(XFILIAL("SE1")+(cAliasTemp)->E1_PREFIXO+(cAliasTemp)->E1_NUM+(cAliasTemp)->E1_PARCELA+(cAliasTemp)->E1_TIPO))

					If !Empty(SE1->E1_NUMBCO)
						cNroDoc 	:= Alltrim(SE1->E1_NUMBCO)
						cDigNosso 	:= SE1->E1_XDVNNUM
						_cont:=1
					EndIf

					lAchou := .T.

					if SE1->(FieldPos("E1_XIMPBOL")) > 0 
						RecLock("SE1",.F.) // Define Boleto como impresso
						SE1->E1_XIMPBOL := 'S'
						SE1->(MsUnlock())
					endif
				EndIf

				If Empty(cNroDoc)

					Begin Transaction

						RecLock("SEE")

						If SEE->EE_CODIGO == '001' // Banco do Brasil

							If Len( AllTrim(SEE->EE_CODEMP) ) < 7
								cNroDoc   := StrZero((Val(Alltrim(SEE->EE_FAXATU))+1),5)
								cDigNosso := Dig11BB(AllTrim(SEE->EE_CODEMP)+cNroDoc )
							ElseIf Len( AllTrim(SEE->EE_CODEMP) ) == 7
								cNroDoc   := StrZero((Val(Alltrim(SEE->EE_FAXATU))+1),10)
								cDigNosso := ""
							EndIf

						ElseIf SEE->EE_CODIGO == '341' //Itaú

							cNroDoc		:= StrZero((Val(Alltrim(SEE->EE_FAXATU))+1),8)
							cTexto		:= aDadosBanco[03] + aDadosBanco[04] + aDadosBanco[6] + cNroDoc
							cDigNosso	:= Modu10(cTexto)

						ElseIf SEE->EE_CODIGO == '237' // Bradesco

							cNroDoc   := StrZero((Val(Alltrim(SEE->EE_FAXATU))+1),11)

							If aDadosBanco[6] == "02"
								If IsInCallStack("U_WFRNBA")
									cDigNosso := Modu11(Alltrim(aDadosBanco[6]) + cNroDoc ,7 ,'P')
								Else
									cDigNosso := Modu11(Alltrim(aDadosBanco[6]) + cNroDoc ,7)
								EndIf
							Else
								cDigNosso := BradMod11(Alltrim(aDadosBanco[6]) + cNroDoc)
							EndIf

						ElseIf SEE->EE_CODIGO $ '033'	// Santander

							cNroDoc := StrZero((Val(Alltrim(SEE->EE_FAXATU))+1),12)
							cDigNosso := Dig11Santander(@cNroDoc)

						ElseIf SEE->EE_CODIGO $ '422'	// Safra

							cNroDoc := StrZero((Val(Alltrim(SEE->EE_FAXATU))+1),8)
							cDigNosso := Dig11Safra(@cNroDoc)

						ElseIf SEE->EE_CODIGO $ '756'	// SICOOB

							cNroDoc   := StrZero((Val(Alltrim(SEE->EE_FAXATU))+1),7)
							cDigNosso := DigNNSicoob(cNroDoc,AllTrim(SEE->EE_CODEMP),AllTrim(SEE->EE_AGENCIA))
						Else
							cNroDoc := '9999999999'
						EndIf

						RecLock("SE1",.F.)
						SE1->E1_NUMBCO  := cNroDoc // Nosso número
						SE1->E1_XDVNNUM := cDigNosso // Dígito verificador do nosso número
						SE1->(MsUnlock())

						// Atuliza a faixa atual do parametro banco
						RecLock("SEE",.F.)
						SEE->EE_FAXATU := cNroDoc
						SEE->(MsUnlock())

					End Transaction
				EndIf

				//Monta codigo de barras
				aCB_RN_NN := Ret_cBarra((cAliasTemp)->E1_PREFIXO,(cAliasTemp)->E1_NUM,(cAliasTemp)->E1_PARCELA,(cAliasTemp)->E1_TIPO,;
					Subs(aDadosBanco[1],1,3),aDadosBanco[3],aDadosBanco[4] ,aDadosBanco[5],;
					cNroDoc,((cAliasTemp)->E1_VLCRUZ + (cAliasTemp)->E1_ACRESC - (cAliasTemp)->E1_DECRESC - nVlrAbat),aDadosBanco[6],"9")

				aDadosTit := {(cAliasTemp)->E1_NUM + AllTrim((cAliasTemp)->E1_PARCELA)	,;  						// [1] Número do título
				(cAliasTemp)->E1_EMISSAO                         	,; 							// [2] Data da emissão do título
				dDataBase          							,;							// [3] Data da emissão do boleto
				(cAliasTemp)->E1_VENCREA                          	,; 							// [4] Data do vencimento
				((cAliasTemp)->E1_SALDO + (cAliasTemp)->E1_ACRESC - (cAliasTemp)->E1_DECRESC - nVlrAbat)  ,;	// [5] Valor do título
				aCB_RN_NN[3]                       			,;  						// [6] Nosso número (Ver fórmula para calculo) // de 3 coloquei 9
				(cAliasTemp)->E1_PREFIXO							,;  						// [7] Prefixo da NF
				"DM"										,;							// [8] Tipo do Titulo
				(cAliasTemp)->E1_SALDO * ((cAliasTemp)->E1_DESCFIN/100)  	,;							// [9] Desconto financeiro
				(cAliasTemp)->E1_VALOR								,;  						// [10] Valor Original do Título // Gianluka Moraes | 23/12/2016
				(cAliasTemp)->E1_ACRESC								,;  						// [11] Acréscimo // Gianluka Moraes | 23/12/2016
				(cAliasTemp)->E1_DECRESC							,;  						// [12] Decréscimo // Gianluka Moraes | 23/12/2016
				(cAliasTemp)->E1_HIST								}   						// [13] Histórico // Gianluka Moraes | 23/12/2016

				If lAchou
					Reclock("SE1",.F.)
					SE1->E1_CODBAR := aCB_RN_NN[1] //Incluido Raphael - Codigo de Barra
					SE1->(MsUnlock())
				EndIf

				// Tratativa ALUGUEL a Receber MARAJO
				If Alltrim((cAliasTemp)->E1_PREFIXO) $ "ALU/ENE" .And. Alltrim((cAliasTemp)->E1_TIPO) == "BOL"
					aBolText[1] := ""
					aBolText[2] := "ATENÇÃO SR. CAIXA: "
					aBolText[3] := "NÃO RECEBER APÓS VENCIMENTO"
				Else
					aBolText[1] := IIF( Empty(aBolText[1]),"", aBolText[1])

					If Subs(aDadosBanco[1],1,3) $ "033/341/001/422/756"

						aBolText[2] := "APOS VENCTO COBRAR MULTA + MORA P/ DIA ATRASO "

						If nMVMULTA > 0

							If lMarajo
								aBolText[3] := "MULTA ........................... "+AllTrim(Transform(nMVMULTA,"@E 999.99"))+" %"
							Else
								aBolText[3] := "MULTA ........................... R$ "+AllTrim(Transform(((cAliasTemp)->E1_SALDO*(nMVMULTA/100)),"@E 999,999,999.99"))
							EndIf
						EndIf
						If (nMVTXPER > 0 .And. nMVMULTA > 0) .Or. lMarajo

							If lMarajo
								aBolText[4] := "MORA ............................ "+AllTrim(Transform(Eval(bGetMvFil,"MV_XTXPER",.F.,0.10),"@E 999.99"))+" % AO DIA"
							Else
								xJurmora := ((cAliasTemp)->E1_VALOR + (cAliasTemp)->E1_ACRESC - (cAliasTemp)->E1_DECRESC)*(nMVTXPER/100)
								aBolText[4] := "MORA P/ DIA ATRASO... R$ "+AllTrim(Transform(xJurmora,"@E 999,999,999.99"))+"."
							EndIf

						ElseIf nMVTXPER > 0

							If lMarajo
								aBolText[3] := "MORA ............................ "+AllTrim(Transform(Eval(bGetMvFil,"MV_XTXPER",.F.,0.10),"@E 999.99"))+" % AO DIA"
							Else
								xJurmora := ((cAliasTemp)->E1_VALOR + (cAliasTemp)->E1_ACRESC - (cAliasTemp)->E1_DECRESC)*(nMVTXPER/100)
								aBolText[3] := "MORA P/ DIA ATRASO... R$ "+AllTrim(Transform(xJurmora,"@E 999,999,999.99"))
							EndIf
						EndIf

						If lMarajo
							aBolText[6]	:= "NAO RECEBER APOS 30 DIAS DO VENCIMENTO"
						EndIf

						// Renegociação
						If (cAliasTemp)->E1_PREFIXO == "REN" .And. !Empty(AllTrim((cAliasTemp)->E1_HIST))

							If lMarajo
								aBolText[7] := (cAliasTemp)->E1_HIST
							Else
								If nDiasProt > 0
									aBolText[7] := AllTrim((cAliasTemp)->E1_HIST) + " - SUJEITO A PROTESTO APOS "+cValToChar(nDiasProt)+" DIAS DO VENCIMENTO"
								EndIf
							EndIf
						Else

							If !lMarajo
								If nDiasProt > 0
									aBolText[7] := "SUJEITO A PROTESTO APOS "+cValToChar(nDiasProt)+" DIAS DO VENCIMENTO"
								EndIf
							EndIf
						EndIf
					Else

						aBolText[2] := "ATENÇÃO SR. CAIXA: "

						If nMVMULTA > 0

							If lMarajo
								aBolText[3] := "APOS VENCTO, MULTA DE "+ AllTrim(Transform(nMVMULTA,"@R 999.99 %")) +""
							Else
								aBolText[3] := "APOS VENCTO, MULTA DE "+ AllTrim(Transform(nMVMULTA,"@R 99.99 %")) +" no Valor de R$ "+AllTrim(Transform(((cAliasTemp)->E1_SALDO*(nMVMULTA/100)),"@E 99,999.99"))
							EndIf
						EndIf

						If nMVTXPER > 0 .and. nMVMULTA > 0 .or. lMarajo

							If lMarajo
								aBolText[4] := "MORA DIARIA DE "+ AllTrim(Transform(Eval(bGetMvFil,"MV_XTXPER",.F.,0.10),"@R 999.99 %")) +""
							Else
								aBolText[4] := "MORA MENSAL DE "+ AllTrim(Transform(nMVTXPER,"@R 99.99 %")) +" no valor de R$ "+AllTrim(Transform(( ( (cAliasTemp)->E1_SALDO*nMVTXPER )/100),"@E 99,999.99"))+"."
							EndIf

						ElseIf nMVTXPER > 0

							If lMarajo
								aBolText[3] := "MORA DIARIA DE "+ AllTrim(Transform(Eval(bGetMvFil,"MV_XTXPER",.F.,0.10),"@R 999.99 %")) +""
							Else
								aBolText[3] := "MORA MENSAL DE "+ AllTrim(Transform(nMVTXPER,"@R 99.99 %")) +" no valor de R$ "+AllTrim(Transform(( ( (cAliasTemp)->E1_SALDO*nMVTXPER )/100),"@E 99,999.99"))
							EndIf
						EndIf

						// Renegociação
						If (cAliasTemp)->E1_PREFIXO == "REN" .And. !Empty(AllTrim((cAliasTemp)->E1_HIST))

							If lMarajo
								aBolText[7] := (cAliasTemp)->E1_HIST
							Else
								If nDiasProt > 0
									aBolText[7] := AllTrim((cAliasTemp)->E1_HIST) + " - SUJEITO A PROTESTO APOS "+cValToChar(nDiasProt)+" DIAS DO VENCIMENTO"
								EndIf
							EndIf
						Else
							If !lMarajo
								If nDiasProt > 0
									aBolText[7] := "SUJEITO A PROTESTO APOS "+cValToChar(nDiasProt)+" DIAS DO VENCIMENTO"
								EndIf
							EndIf
						EndIf
					EndIf
				EndIf

				// Mensagem Desconto
				If aDadosTit[9] > 0  .And. aDadosTit[4] >= dDataBase
					aBolText[5] := "Desconto concedido de R$ "+AllTrim(Transform(aDadosTit[9] ,"@E 99,999.99"))+" para pagamento até a data de vencimento."
				Else
					aBolText[5] := ""
				EndIf

				ImpConf(3,_cDef2Printer,aDadosEmp,aDadosTit,aDadosBanco,aDatSacado,aBolText,aCB_RN_NN,cNroDoc) // Impressão em PDF

				If !lMo

					// Envio do boleto por e-mail
					//If ValType(lEnvMail) <> 'U' .And. lEnvMail .And. IsBlind() .And. !IsInCallStack("U_WFRNBA")
					//	cMail := SE1->E1_XEMAIL
					//	ImpConf(1,_cDef2Printer,aDadosEmp,aDadosTit,aDadosBanco,aDatSacado,aBolText,aCB_RN_NN,cNroDoc,cMail) //Impressão em PDF

					//ElseIf !IsBlind() .And. !IsInCallStack("U_TRETE017") .And. !IsInCallStack("U_TRETE030") .And. ApMsgYesNo('Deseja enviar o boleto por e-mail?')
					//	cMail := RetField("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_EMAIL")
					//	ImpConf(1,_cDef2Printer,aDadosEmp,aDadosTit,aDadosBanco,aDatSacado,aBolText,aCB_RN_NN,cNroDoc,cMail) // Impressão em PDF

					//ElseIf !IsBlind() .And. !IsInCallStack("U_TRETE017") .and. ValType(lEnvMail) <> 'U' .And. lEnvMail // Envio por e-mail
					//	cMail := DestMail(SE1->E1_CLIENTE,SE1->E1_LOJA)
					//	ImpConf(1,_cDef2Printer,aDadosEmp,aDadosTit,aDadosBanco,aDatSacado,aBolText,aCB_RN_NN,cNroDoc,cMail) // Impressão em PDF

					If !IsBlind() .And. !_lImprime .And. ValType(lEnvMail) == 'U' .And. ValType(_cDef2Printer) == 'U'
						ImpConf(4,_cDef2Printer,aDadosEmp,aDadosTit,aDadosBanco,aDatSacado,aBolText,aCB_RN_NN,cNroDoc,"") // Impressão em Tela
					EndIf

					If _lImprime //Realiza impressão física
						ImpConf(2,_cDef2Printer,aDadosEmp,aDadosTit,aDadosBanco,aDatSacado,aBolText,aCB_RN_NN,cNroDoc,"") // Impressão em Spool
					EndIf

					nX := nX + 1
				EndIf
			EndIf
		EndIf

		aParApi := {cEmpAnt,SE1->E1_FILIAL,SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,SE1->E1_CODBAR,SE1->E1_PORTADO}
		///////////////////////////////////////////////////////////////////////////////////////////
		//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR             		 //
		///////////////////////////////////////////////////////////////////////////////////////////
		aAreaSe1 := SE1->(GetArea())
		If lPe009API
			ExecBlock("TR009API",.F.,.F.,aParApi)
		EndIf
		RestArea(aAreaSe1)

		(cAliasTemp)->(DbSkip())
		lAchou := .F.
		nI += 1
	EndDo

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} ImpConf
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function ImpConf(nOpc,_cDef2Printer,aDadosEmp,aDadosTit,aDadosBanco,aDatSacado,aBolText,aCB_RN_NN,cNroDoc,cMail)

	Local oPrint
	Local lDisableStp	:= If(ValType(_cDef2Printer) == "U" .And. nOpc == 2,.F.,.T.)
	Local cStartPath	:= GetPvProfString(GetEnvServer(),"StartPath","ERROR",GetAdv97())
	Local cMask := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"

//Marajó Online
	Local cNomEmp 	:= SuperGetMv("MV_XNOMEMP",.F.,"MV_XNOMEMP")
	Local cDirBol		:= SuperGetMv("MV_XTMPBOL",.F.,"faturamento_automatico\boletos\")
	Local cDirBolRel	:= SuperGetMv("MV_XTMBREL",.F.,"\system\faturamento_automatico\boletos\rel\")
	Local cDirDes  		:= SuperGetMv("MV_XDIRBMO",.F.,"arquivos_mo\boletos\") //destino dos arquivos (arquivos_mo\boletos\)
	Local cDirSystem	:= SuperGetMv("MV_XDIRSYS",.F.,"C:\TOTVS\Protheus11\Data\Protheus_Data_Ofc\system\")
	Local aDirAux  		:= {} //Directory(cDirBol+'*.pdf')
	Local nAtual		:= 0
	Local cNomArq  		:= ""
	Local cDirSrv		:= ""
	Local cTmpUser		:= IIF(!IsBlind(),GetTempPath(),"")

	Local cSufixo 		:= ""
	Local nQtdRen		:= 0

	Local cRespCob		:= ""

	If nOpc <> 3 // Diferente impressão PDF
		cFilePrint := "BOLETO"+ cFilAnt + Str( Year( date() ),4) + StrZero( Month( date() ), 2) +;
			StrZero( Day( date() ),2) + Left(Time(),2) + Substr(Time(),4,2) + Right(Time(),2)
	Else

		If lMarajo

			// Renegociação
			If SE1->E1_PREFIXO == "REN"

				nQtdRen	:= RetQtdRen(SE1->E1_CLIENTE,SE1->E1_LOJA,SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_TIPO)
				cSufixo := "_REN" + cValToChar(nQtdRen)
				cFilePrint := cFilAnt + SE1->E1_NUM + cSufixo
			Else
				cFilePrint := cFilAnt + SE1->E1_NUM
			EndIf
		Else

			cFilePrint	:= "BOLETO_" + Alltrim(SE1->E1_FILIAL) + "_" + AllTrim(SE1->E1_NUM) + "_" + AllTrim(SE1->E1_CLIENTE) + AllTrim(SE1->E1_LOJA) + "_" +;
				Upper(AllTrim(SE1->E1_NOMCLI)) + "_" + SubStr(DToS(dDataBase),7,2) + SubStr(DToS(dDataBase),5,2) + SubStr(DToS(dDataBase),1,4)
			
			//trato nome arquivo 
			cFilePrint := StrTran(cFilePrint," ","_")
			cFilePrint := U_MYNOCHAR(cFilePrint, cMask)

			//Exclui arquivo caso exista
			If FErase(cTmpUser + cFilePrint + ".pdf") == 0
				//conout(" >> Excluido arquivo <"+ cTmpUser + cFilePrint + ".pdf" +">")
			EndIf
			If FErase("system\" + cDirDes + cFilePrint + ".pdf") == 0
				//conout(" >> Excluido arquivo <"+ "system\" + cDirDes + cFilePrint + ".pdf" +">")
			EndIf
		EndIf
	EndIf

	If lMarajo
		//Excluir arquivos .rel e ._pd
		ExcRelPd(cFilePrint,cDirBol,cDirBolRel)
	EndIf

	If nOpc ==  4 // Impressão em Tela
		oPrint := TMSPrinter():New("")
	Else

		If nOpc == 3 // Impressão PDF
			oPrint := FWMSPrinter():New(cFilePrint,,.T.,cDirBolRel,.T.,.T.,,,.T.,.F.,,,)
		Else
			oPrint := FWMSPrinter():New(cFilePrint /*1-Arq. Spool*/,2/*2-Spool/PDF*/, .T. /*3-Legado*/,/*SuperGetMv("MV_XDIRBOL",,GetTempPath())*/ /*4-Dir. Salvar*/,lDisableStp,;
									/*!ValType(_cDef2Printer) == "U" /*5-Não Exibe Setup,*/ /*6-Classe TReport*/,;
									/*7-oPrintSetup*/, IIF(ValType(_cDef2Printer) == "U","",_cDef2Printer) /*8-Impressora Forçada*/ )

			If !_MsExec .AND. oPrint:nModalResult != PD_OK
				oPrint := Nil
				Return
			endif
		EndIf

		oPrint:SetResolution(78) //Tamanho estipulado para a Danfe
		oPrint:SetMargin(60,60,60,60)
	EndIf

	oPrint:SetPortrait()
	oPrint:SetPaperSize(DMPAPER_A4)

	If nOpc == 4 //Impressão em Tela
		Impress(oPrint,aDadosEmp,aDadosTit,aDadosBanco,aDatSacado,aBolText,aCB_RN_NN,cNroDoc,.T.)
	Else
		Impress(oPrint,aDadosEmp,aDadosTit,aDadosBanco,aDatSacado,aBolText,aCB_RN_NN,cNroDoc)
	EndIf

	If nOpc <> 2 //PDV ou Marajo Online

		If nOpc == 1 //PDV

			oPrint:cPathPDF := SuperGetMv("MV_XDIRBOL",,GetTempPath())
			oPrint:cPrinter := "PDF"
			oPrint:SetViewPDF(.F.)
			oPrint:SetDevice(IMP_PDF)
			oPrint:Print()

			cDirBol := "system\"+cDirBol
			cDirDes := "system\"+cDirDes

			aDirAux := Directory(cDirBol+'*.pdf')

			//Percorre os arquivos
			For nAtual := 1 To Len(aDirAux)

				//Pegando o nome do arquivo
				cNomArq := aDirAux[nAtual][1]
				//Pegando o tamanho do arquivo
				nTamArq := aDirAux[nAtual][2]

				If nTamArq > 0

					If __CopyFile(cDirBol+cNomArq, cDirDes+cNomArq)
						//conout(" >> Copiado arquivo <"+cDirBol+cNomArq+"> para o diretorio do Marajo On-Line: "+cDirDes+cNomArq)
					EndIf

					If FErase(cDirBol+cNomArq) == 0
						//conout(" >> Excluido arquivo <"+cDirBol+cNomArq+">")
					EndIf
				Else

					If FErase(cDirBol+cNomArq) == 0
						//conout(" >> Excluido arquivo <"+cDirBol+cNomArq+">")
					EndIf

					lRet := .F.
				EndIf
			Next nAtual

		ElseIf nOpc == 4 //Em Tela
			oPrint:Preview() //Visualiza antes de imprimir
		Else

			If !IsBlind()

				oPrint:cPathPDF := cTmpUser
				oPrint:cPrinter := "PDF"

			Else //JOB - Faturamento Automático
				If lMarajo
					If IsInCallStack("U_WFRNBA")
						oPrint:cPathPDF := "\system\Boleto\"
					Else
						oPrint:cPathPDF := cDirSystem + cDirBol
					EndIf
				Else
					oPrint:cPathPDF := cDirSystem + cDirDes

					//Anexo a ser enviado por e-mail
					If Type("aArqPDF") <> "U"
						//conout("Anexo boleto bancario: " + "\system\" + cDirDes + cFilePrint)
						AAdd(aArqPDF,"\system\" + cDirDes + cFilePrint)
					EndIf
					If Type("__aArqPDF") <> "U"
						//conout("Anexo boleto bancario: " + "\system\" + cDirDes + cFilePrint)
						AAdd(__aArqPDF,"\system\" + cDirDes + cFilePrint)
					EndIf
				EndIf
			EndIf

			oPrint:SetViewPDF(.F.)
			oPrint:SetDevice(IMP_PDF)
			oPrint:Print()

			If !IsBlind()

				If lMarajo
					cStartPath += If(Right(cStartPath, 1) <> "\", "\", "")
					cDirSrv := cStartPath + cDirBol
					CpyT2S(cTmpUser + cFilePrint + ".pdf",cDirSrv,.T.)
					FErase(cTmpUser + cFilePrint + ".pdf")  //Deleta arquivo do Temp se houver
				Else

					//Anexo a ser enviado por e-mail
					If Type("aArqPDF") <> "U"
						//conout("Anexo boleto bancario: " + "\system\" + cDirDes + cFilePrint)
						AAdd(aArqPDF,"\system\" + cDirDes + cFilePrint)
					EndIf
					If Type("__aArqPDF") <> "U"
						//conout("Anexo boleto bancario: " + "\system\" + cDirDes + cFilePrint)
						AAdd(__aArqPDF,"\system\" + cDirDes + cFilePrint)
					EndIf

					If CpyT2S(cTmpUser + cFilePrint + ".pdf","\system\"+cDirDes,.T.)
						//conout(" >> Copiado arquivo <"+cTmpUser + cFilePrint + ".pdf"+"> para o Servidor: " + "\system\"+cDirDes)
					EndIf
					If FErase(cTmpUser + cFilePrint + ".pdf") == 0  //Deleta arquivo do Temp se houver
						//conout(" >> Excluido arquivo <"+cTmpUser + cFilePrint + ".pdf"+">")
					EndIf
				EndIf
			EndIf

			If lMarajo

				cDirBol := "system\"+cDirBol
				cDirDes := "system\"+cDirDes

				aDirAux := Directory(cDirBol+'*.pdf')

				//Percorre os arquivos
				For nAtual := 1 To Len(aDirAux)

					//Pegando o nome do arquivo
					cNomArq := aDirAux[nAtual][1]
					//Pegando o tamanho do arquivo
					nTamArq := aDirAux[nAtual][2]

					If nTamArq > 0

						If __CopyFile(cDirBol+cNomArq, cDirDes+cNomArq)
							//conout(" >> Copiado arquivo <"+cDirBol+cNomArq+"> para o diretorio do Marajo On-Line: "+cDirDes+cNomArq)
						EndIf

						If FErase(cDirBol+cNomArq) == 0
							//conout(" >> Excluido arquivo <"+cDirBol+cNomArq+">")
						EndIf
					Else

						If FErase(cDirBol+cNomArq) == 0
							//conout(" >> Excluido arquivo <"+cDirBol+cNomArq+">")
						EndIf

						lRet := .F.
					EndIf
				Next nAtual
			EndIf
		EndIf
	Else

		If lEntPeloMenosVez

			If ValType(_cDef2Printer) == "U"
				oPrint:Preview()
			Else
				oPrint:Print()

				If !IsBlind()

					If lMarajo
						cStartPath += If(Right(cStartPath, 1) <> "\", "\", "")
						cDirSrv := cStartPath + cDirBol
						CpyT2S(cTmpUser + cFilePrint+".pdf",cDirSrv,.T.)
						FErase(cTmpUser + cFilePrint+".pdf")  //Deleta arquivo do Temp se houver
					Else
						cDirSrv := cStartPath + cDirBol
						CpyT2S(cTmpUser + cFilePrint+".pdf",cDirSrv,.T.)
						//CpyT2S(cTmpUser + cFilePrint+".pdf",cDirDes,.T.)
						FErase(cTmpUser + cFilePrint+".pdf")  //Deleta arquivo do Temp se houver
					EndIf
				EndIf

				If lMarajo

					cDirBol := "system\"+cDirBol
					cDirDes := "system\"+cDirDes

					aDirAux := Directory(cDirBol+'*.pdf')

					//Percorre os arquivos
					For nAtual := 1 To Len(aDirAux)

						//Pegando o nome do arquivo
						cNomArq := aDirAux[nAtual][1]
						//Pegando o tamanho do arquivo
						nTamArq := aDirAux[nAtual][2]

						If nTamArq > 0

							If __CopyFile(cDirBol+cNomArq, cDirDes+cNomArq)
								//conout(" >> Copiado arquivo <"+cDirBol+cNomArq+"> para o diretorio do Marajo On-Line: "+cDirDes+cNomArq)
							EndIf

							If FErase(cDirBol+cNomArq) == 0
								//conout(" >> Excluido arquivo <"+cDirBol+cNomArq+">")
							EndIf
						Else

							If FErase(cDirBol+cNomArq) == 0
								//conout(" >> Excluido arquivo <"+cDirBol+cNomArq+">")
							EndIf

							lRet := .F.
						EndIf
					Next nAtual
				EndIf
			EndIf
		EndIf
	EndIf

	If nOpc == 1 .And. !IsInCallStack("U_WFRNBA") //Envia email e apaga pdf gerado

		If File(SuperGetMv("MV_XDIRSER",,"\system")+cFilePrint+".pdf")
			FErase(SuperGetMv("MV_XDIRSER",,"\system")+cFilePrint+".pdf")  //Deleta arquivo do Servidor se houver
		EndIf

		If CpyT2S( SuperGetMv("MV_XDIRBOL",,GetTempPath())+cFilePrint+".pdf",SuperGetMv("MV_XDIRSER",,"\system"), .T. )

			oMail := LTpSendMail():New(AllTrim(cMail), "Boleto Bancario "+dtoc(date())+' '+time() + " "+AllTrim(cNomEmp), "Segue em anexo Boleto Bancário!")
			oMail:SetAttachment(SuperGetMv("MV_XDIRSER",,"\system")+cFilePrint+".pdf")
			oMail:Send()
			FErase(SuperGetMv("MV_XDIRBOL",,GetTempPath())+cFilePrint+".pdf") 	   //Deletar Arquivo no remote
			FErase(SuperGetMv("MV_XDIRSER",,"\system")+cFilePrint+".pdf")  //Deletar Arquivo no Servidor
		EndIf

	ElseIf IsInCallStack("U_WFRNBA")

		cRespCob := Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_XOPCOBR")

		If !Empty(AllTrim(cRespCob))
			cRespCob := UsrRetMail(Posicione("SU7",1,xFilial("SU7")+cRespCob,"U7_CODUSU"))
		EndIf
	
		cMail := DestMail(SE1->E1_CLIENTE,SE1->E1_LOJA) + ";" + cRespCob
		cMail := StrTran(cMail, ";", "," )
		oMail := LTpSendMail():New(AllTrim(cMail), "Boleto Bancario Solicitado via Workflow "+dtoc(date())+' '+time(), "")
		oMail:SetAttachment("\system\Boleto\"+cFilePrint+".pdf")	
		oMail:Send()                                                                                         

		If SuperGetMv("MV_XWFRNO",,.F.)
			If __CopyFile( "\system\Boleto\"+cFilePrint+".pdf","\system\arquivos_mo\boletos\"+cFilePrint+".pdf") 
				Conout("COPYFILE SIM")	
			Else
				Conout("COPYFILE NAO")
			Endif                
		EndIf

		If File("\system\Boleto\"+cFilePrint+".pdf")
			FErase(SuperGetMv("MV_XDIRSER",,"\system")+cFilePrint+".pdf")  //Deleta arquivo do Servidor se houver
		Endif
	EndIf

	oPrint := Nil

Return(oPrint)

//-------------------------------------------------------------------
/*/{Protheus.doc} Impress
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function Impress(oPrint,aDadosEmp,aDadosTit,aDadosBanco,aDatSacado,aBolText,aCB_RN_NN,aNossoN,lImpTela)

	Local oFont8
	Local oFont11c
	Local oFont10
	Local oFont14
	Local oFont16n
	Local oFont15
	Local oFont14n
	Local oFont24
	Local nI         	:= 0
	Local cStartPath 	

	Default lImpTela	:= .F.

	cStartPath := GetPvProfString(GetEnvServer(),"StartPath","ERROR",GetAdv97())
	cStartPath += If(Right(cStartPath, 1) <> "\", "\", "") 

	oFont11c := TFont():New("Courier New",9,11,.T.,.T.,5,.T.,5,.T.,.F.)

	oFont8		:= TFont():New("Arial",9, 8,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont10		:= TFont():New("Arial",9,10,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont10n	:= TFont():New("Arial",9,10,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont11 	:= TFont():New("Arial",9,11,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont11n	:= TFont():New("Arial",9,11,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont12 	:= TFont():New("Arial",9,12,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont12n	:= TFont():New("Arial",9,12,.T.,.f.,5,.T.,5,.T.,.F.)
	oFont14 	:= TFont():New("Arial",9,14,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont14n	:= TFont():New("Arial",9,14,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont15 	:= TFont():New("Arial",9,15,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont15n 	:= TFont():New("Arial",9,15,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont16n 	:= TFont():New("Arial",9,16,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont18  	:= TFont():New("Arial",9,18,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont20  	:= TFont():New("Arial",9,20,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont21  	:= TFont():New("Arial",9,21,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont24  	:= TFont():New("Arial",9,24,.T.,.T.,5,.T.,5,.T.,.F.)

// Inicia uma nova página
	oPrint:StartPage()

/******************/
/* PRIMEIRA PARTE */
/******************/
	If lImpTela//Impressão em Tela
		nRow1	:= 60
		nRowSay := 70
	Else
		nRow1	:= 0
		nRowSay := 25
	EndIf

	oPrint:Line(nRow1+0150,500,nRow1+0070, 500)
	oPrint:Line(nRow1+0150,710,nRow1+0070, 710)

	If lImpTela//Impressão em Tela

		oPrint:Say(nRowSay+0060,513,aDadosBanco[1]+"-"+aDadosBanco[7] ,oFont20 ) // [1]Numero do Banco + [7] DV Banco

		If AllTrim(SEE->EE_CODIGO) == "033"
			oPrint:SayBitmap(nRow1+0055,100,cStartPath+"santander.jpg",400,090)

		ElseIf AllTrim(SEE->EE_CODIGO) == "422"
			//oPrint:SayBitmap(nRow1+0055,100,cStartPath+"safra.jpg",400,090)
			oPrint:Say(nRow1+0080,100,aDadosBanco[2] ,oFont10 )

		ElseIf AllTrim(SEE->EE_CODIGO) == "237"
			oPrint:SayBitmap(nRow1+0055,100,cStartPath+"bradesco.jpg",390,095)

		ElseIf AllTrim(SEE->EE_CODIGO) == "341"

			If lMarajo
				oPrint:SayBitmap(nRow1+0050,100,cStartPath+"itau.jpg",400,100)
			Else
				oPrint:SayBitmap(nRow1+0050,100,cStartPath+"itau.jpg",120,100)
			EndIf

		ElseIf AllTrim(SEE->EE_CODIGO) == "756"
			oPrint:SayBitmap(nRow1+0055,100,cStartPath+"sicoob_logo.jpg",395,090)

		ElseIf AllTrim(SEE->EE_CODIGO) == "001"
			oPrint:SayBitmap(nRow1+0055,100,cStartPath+"bb2.jpg",400,090)
		Else
			oPrint:Say(nRowSay+0080,100,aDadosBanco[2],oFont12 )
		EndIf
	Else

		oPrint:Say(nRowSay+0095,513,aDadosBanco[1]+"-"+aDadosBanco[7] ,oFont20 )	// [1]Numero do Banco   + [7] DV Banco

		If AllTrim(SEE->EE_CODIGO) == "033"
			oPrint:SayBitmap(nRow1+0070,100,cStartPath+"santander.jpg",400,075)

		ElseIf AllTrim(SEE->EE_CODIGO) == "422"
			//oPrint:SayBitmap(nRow1+0070,100,cStartPath+"safra.jpg",400,075)
			oPrint:Say(nRow1+0100,100,aDadosBanco[2] ,oFont10 )

		ElseIf AllTrim(SEE->EE_CODIGO) == "237"
			oPrint:SayBitmap(nRow1+0070,100,cStartPath+"bradesco.jpg",390,080)

		ElseIf AllTrim(SEE->EE_CODIGO) == "341"

			If lMarajo
				oPrint:SayBitmap(nRow1+0065,100,cStartPath+"itau.jpg",400,085)
			Else
				oPrint:SayBitmap(nRow1+0065,100,cStartPath+"itau.jpg",120,085)
			EndIf

		ElseIf AllTrim(SEE->EE_CODIGO) == "756"
			oPrint:SayBitmap(nRow1+0070,100,cStartPath+"sicoob_logo.jpg",395,075)

		ElseIf AllTrim(SEE->EE_CODIGO) == "001"
			oPrint:SayBitmap(nRow1+0070,100,cStartPath+"bb2.jpg",400,075)
		Else
			oPrint:Say(nRowSay+0095,100,aDadosBanco[2],oFont12 )
		EndIf
	EndIf

	oPrint:Say(nRowSay+0084,1900,"Comprovante de Entrega",oFont10n)
	oPrint:Line (nRow1+0150,100,nRow1+0150,2300)

	oPrint:Say(nRowSay+0150,100 ,"Beneficiário",oFont8)
	if lImpTela
		oPrint:Say(nRowSay+0200,100 ,SubStr(aDadosEmp[1],1,43),oFont10n)	// Nome + CNPJ
	else
		oPrint:Say(nRowSay+0200,100 ,SubStr(aDadosEmp[1],1,50),oFont10n)	// Nome + CNPJ
	endif

	oPrint:Say(nRowSay+0150,1060,"Agência/Código Beneficiário",oFont8)
	If aDadosBanco[1] == '001'
		cString := Alltrim(aDadosBanco[3]+iif(!Empty(aDadosBanco[10]),"-"+aDadosBanco[10],"")+"/"+iif(Empty(aDadosBanco[11]),aDadosBanco[4]+"-"+aDadosBanco[5], aDadosBanco[12]))

	ElseIf aDadosBanco[1] $ '237'
		cString := Alltrim(StrZero(Val(aDadosBanco[3]),4)+iif(!Empty(aDadosBanco[10]),"-"+aDadosBanco[10],"")+"/"+IIF(!EMPTY(aDadosBanco[5]),StrZero(Val(aDadosBanco[4]),7)+"-"+aDadosBanco[5],StrZero(Val(Left(aDadosBanco[4],len(aDadosBanco[4])-1)),7)+"-"+Right(aDadosBanco[4],1)))

	ElseIf aDadosBanco[1] $ '033/756'
		cString := Alltrim(aDadosBanco[3]+iif(!Empty(aDadosBanco[10]),"-"+aDadosBanco[10],"")+"/"+iif(Empty(aDadosBanco[11]),aDadosBanco[4]+"-"+aDadosBanco[5], aDadosBanco[11]))

	ElseIf aDadosBanco[1] $ "341"
		cString := Alltrim(aDadosBanco[3]+"/"+aDadosBanco[4]+"-"+aDadosBanco[5])

	ElseIf aDadosBanco[1] $ "422"
		cString := Alltrim(PADR(CValToChar(Val(aDadosBanco[3])),5,"0")+"/"+aDadosBanco[4]+aDadosBanco[5])

	Else
		cString := Alltrim(aDadosBanco[3]+iif(!Empty(aDadosBanco[10]),"-"+aDadosBanco[10],"")) +"/"+aDadosBanco[4]
	EndIf

	oPrint:Say(nRowSay+0200,1060,cString,oFont10n)

	oPrint:Say(nRowSay+0150,1510,"Nro.Documento",oFont8)
	oPrint:Say(nRowSay+0200,1510,aDadosTit[7]+aDadosTit[1],oFont10n) // Prefixo+Numero+Parcela

	oPrint:Say(nRowSay+0250,100 ,"Pagador",oFont8)
	oPrint:Say(nRowSay+0300,100 ,aDatSacado[1],oFont10n) // Nome

	oPrint:Say(nRowSay+0250,1060,"Vencimento",oFont8)
	oPrint:Say(nRowSay+0300,1060,StrZero(Day((aDadosTit[4])),2) +"/"+ StrZero(Month((aDadosTit[4])),2) +"/"+ Right(Str(Year((aDadosTit[4]))),4),oFont10n)

	oPrint:Say(nRowSay+0250,1510,"Valor do Documento",oFont8)
	oPrint:Say(nRowSay+0300,1550,AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99")),oFont10n)

	oPrint:Say(nRowSay+0400,0100,"Recebi(emos) o bloqueto/título",oFont10)
	oPrint:Say(nRowSay+0430,0100,"com as características acima.",oFont10)

	oPrint:Say(nRowSay+0350,1060,"Data",oFont8)
	oPrint:Say(nRowSay+0350,1410,"Assinatura",oFont8)
	oPrint:Say(nRowSay+0450,1060,"Data",oFont8)
	oPrint:Say(nRowSay+0450,1410,"Entregador",oFont8)

	oPrint:Line(nRow1+0250, 100,nRow1+0250,1900)
	oPrint:Line(nRow1+0350, 100,nRow1+0350,1900)
	oPrint:Line(nRow1+0450,1050,nRow1+0450,1900)
	oPrint:Line(nRow1+0550, 100,nRow1+0550,2300)

	oPrint:Line(nRow1+0550,1050,nRow1+0150,1050)
	oPrint:Line(nRow1+0550,1400,nRow1+0350,1400)
	oPrint:Line(nRow1+0350,1500,nRow1+0150,1500)
	oPrint:Line(nRow1+0550,1900,nRow1+0150,1900)

	oPrint:Say(nRowSay+0165,1910,"(  )Mudou-se"               ,oFont10n)
	oPrint:Say(nRowSay+0195,1910,"(  )Ausente"                ,oFont10n)
	oPrint:Say(nRowSay+0225,1910,"(  )Não existe nº indicado" ,oFont10n)
	oPrint:Say(nRowSay+0255,1910,"(  )Recusado"               ,oFont10n)
	oPrint:Say(nRowSay+0285,1910,"(  )Não procurado"          ,oFont10n)
	oPrint:Say(nRowSay+0315,1910,"(  )Endereço insuficiente"  ,oFont10n)
	oPrint:Say(nRowSay+0345,1910,"(  )Desconhecido"           ,oFont10n)
	oPrint:Say(nRowSay+0375,1910,"(  )Falecido"               ,oFont10n)
	oPrint:Say(nRowSay+0405,1910,"(  )Outros(anotar no verso)",oFont10n)

/*****************/
/* SEGUNDA PARTE */
/*****************/
	If lImpTela // Impressão em Tela
		nRow2  := 60
		nRowSay:= 65
	Else
		nRow2  := 0
		nRowSay:= 25
	EndIf

// Pontilhado separador
	For nI := 100 to 2300 step 50
		oPrint:Line(nRow2+0590, nI,nRow2+0590, nI+30)
	Next nI

	oPrint:Line(nRow2+0710,100,nRow2+0710,2300)
	oPrint:Line(nRow2+0710,500,nRow2+0630, 500)
	oPrint:Line(nRow2+0710,710,nRow2+0630, 710)

	If lImpTela // Impressão em Tela

		oPrint:Say(nRowSay+0625,518,aDadosBanco[1]+"-"+aDadosBanco[7],oFont20 )	// [1]Numero do Banco + [7]Dígito do Banco
		oPrint:Say(nRowSay+0630,730,aCB_RN_NN[2],oFont14N) // Linha Digitavel do Codigo de Barras

		If AllTrim(SEE->EE_CODIGO) == "033"
			oPrint:SayBitmap(nRow1+0615,100,cStartPath+"santander.jpg",400,090)

		ElseIf AllTrim(SEE->EE_CODIGO) == "422"
			//oPrint:SayBitmap(nRow1+0615,100,cStartPath+"safra.jpg",400,090)
			oPrint:Say(nRow1+0645,100,aDadosBanco[2] ,oFont10 )

		ElseIf AllTrim(SEE->EE_CODIGO) == "237"
			oPrint:SayBitmap(nRow1+0615,100,cStartPath+"bradesco.jpg",390,095)

		ElseIf AllTrim(SEE->EE_CODIGO) == "341"

			If lMarajo
				oPrint:SayBitmap(nRow1+0610,100,cStartPath+"itau.jpg",400,100)
			Else
				oPrint:SayBitmap(nRow1+0610,100,cStartPath+"itau.jpg",120,100)
			EndIf

		ElseIf AllTrim(SEE->EE_CODIGO) == "756"
			oPrint:SayBitmap(nRow1+0615,100,cStartPath+"sicoob_logo.jpg",395,090)

		ElseIf AllTrim(SEE->EE_CODIGO) == "001"
			oPrint:SayBitmap(nRow1+0615,100,cStartPath+"bb2.jpg",400,090)

		Else
			oPrint:Say(nRowSay+0645,100,aDadosBanco[2],oFont12 )
		EndIf
	Else

		oPrint:Say(nRowSay+0650,518,aDadosBanco[1]+"-"+aDadosBanco[7],oFont20 )	// [1]Numero do Banco + [7]Dígito do banco
		oPrint:Say(nRowSay+0655,730,aCB_RN_NN[2],oFont18) // Linha Digitavel do Codigo de Barras

		If AllTrim(SEE->EE_CODIGO) == "033"
			oPrint:SayBitmap(nRow1+0630,100,cStartPath+"santander.jpg",400,075)

		ElseIf AllTrim(SEE->EE_CODIGO) == "422"
			//oPrint:SayBitmap(nRow1+0630,100,cStartPath+"safra.jpg",400,075)
			oPrint:Say(nRow1+0660,100,aDadosBanco[2] ,oFont10 )

		ElseIf AllTrim(SEE->EE_CODIGO) == "237"
			oPrint:SayBitmap(nRow1+0630,100,cStartPath+"bradesco.jpg",390,080)

		ElseIf AllTrim(SEE->EE_CODIGO) == "341"

			If lMarajo
				oPrint:SayBitmap(nRow1+0625,100,cStartPath+"itau.jpg",400,085)
			Else
				oPrint:SayBitmap(nRow1+0625,100,cStartPath+"itau.jpg",120,085)
			EndIf

		ElseIf AllTrim(SEE->EE_CODIGO) == "756"
			oPrint:SayBitmap(nRow1+0630,100,cStartPath+"sicoob_logo.jpg",395,075)

		ElseIf AllTrim(SEE->EE_CODIGO) == "001"
			oPrint:SayBitmap(nRow1+0630,100,cStartPath+"bb2.jpg",400,075)

		Else
			oPrint:Say(nRowSay+0660,100,aDadosBanco[2],oFont12 )
		EndIf
	EndIf

	//oPrint:Say(nRowSay+0644,1975,"Recibo do Pagador",oFont10n)

	oPrint:Line(nRow2+0810,100,nRow2+0810,2300)
	oPrint:Line(nRow2+0910,100,nRow2+0910,2300)
	oPrint:Line(nRow2+0980,100,nRow2+0980,2300)
	oPrint:Line(nRow2+1050,100,nRow2+1050,2300)

	//If aDadosBanco[1] $ '341/237/001/033/422/756'
	//	oPrint:Line (nRow2+0850,100,nRow2+0850,1800 )
	//EndIf

	oPrint:Line(nRow2+0910,500,nRow2+1050,500)
	oPrint:Line(nRow2+0980,750,nRow2+1050,750)
	oPrint:Line(nRow2+0910,1000,nRow2+1050,1000)
	oPrint:Line(nRow2+0910,1300,nRow2+0980,1300)
	oPrint:Line(nRow2+0910,1480,nRow2+1050,1480)

	oPrint:Say(nRowSay+0710,100 ,"Local de Pagamento",oFont8)
	oPrint:Say(nRowSay+0725,400 ,aDadosBanco[8] ,oFont10n)
	oPrint:Say(nRowSay+0760,400 ,aDadosBanco[9] ,oFont10n)

	oPrint:Say(nRowSay+0710,1810,"Vencimento",oFont8)
	cString	:= StrZero(Day((aDadosTit[4])),2) +"/"+ StrZero(Month((aDadosTit[4])),2) +"/"+ Right(Str(Year((aDadosTit[4]))),4)
	nCol := 1855+(374-(len(cString)*22))
	oPrint:Say(nRowSay+0750,nCol,cString,oFont12)

	oPrint:Say(nRowSay+0805,100 ,"Beneficiário",oFont8)

	If aDadosBanco[1] $ '341/237/001/033/422/756'

		oPrint:Say(nRowSay+0832,100 ,alltrim(aDadosEmp[1])+" - "+alltrim(aDadosEmp[6])	,oFont10n) //Nome + CNPJ

		If lImpTela // Impressão em Tela
			//oPrint:Say(nRowSay+0842,100 ,"Endereço Beneficiário/Sacador Avalista",oFont8)
			oPrint:Say(nRowSay+0870,100 ,alltrim(aDadosEmp[2])+" "+alltrim(aDadosEmp[3])+" "+alltrim(aDadosEmp[4])	,oFont8) // Nome + CNPJ
		Else
			//oPrint:Say(nRowSay+0842,100 ,"Endereço Beneficiário/Sacador Avalista",oFont8)
			oPrint:Say(nRowSay+0862,100 ,alltrim(aDadosEmp[2])+" "+alltrim(aDadosEmp[3])+" "+alltrim(aDadosEmp[4])	,oFont8) // Nome + CNPJ
		EndIf
	Else
		oPrint:Say(nRowSay+0865,100 ,alltrim(aDadosEmp[1])+" - "+alltrim(aDadosEmp[6])	,oFont10n) //Nome + CNPJ
	EndIf

	oPrint:Say(nRowSay+0810,1810,"Agência/Código Beneficiário",oFont8)
	If aDadosBanco[1] == '001'
		cString := Alltrim(aDadosBanco[3]+iif(!Empty(aDadosBanco[10]),"-"+aDadosBanco[10],"")+"/"+iif(Empty(aDadosBanco[11]),aDadosBanco[4]+"-"+aDadosBanco[5], aDadosBanco[12]))

	ElseIf aDadosBanco[1] == '237'
		cString := Alltrim(StrZero(Val(aDadosBanco[3]),4)+iif(!Empty(aDadosBanco[10]),"-"+aDadosBanco[10],"")+"/"+IIF(!EMPTY(aDadosBanco[5]),StrZero(Val(aDadosBanco[4]),7)+"-"+aDadosBanco[5],StrZero(Val(Left(aDadosBanco[4],len(aDadosBanco[4])-1)),7)+"-"+Right(aDadosBanco[4],1)))

	ElseIf aDadosBanco[1] $ '033/756'
		cString := Alltrim(aDadosBanco[3]+iif(!Empty(aDadosBanco[10]),"-"+aDadosBanco[10],"")+"/"+iif(Empty(aDadosBanco[11]),aDadosBanco[4]+"-"+aDadosBanco[5], aDadosBanco[11]))

	ElseIf aDadosBanco[1] $ '341'
		cString := Alltrim(aDadosBanco[3]+"/"+aDadosBanco[4]+"-"+aDadosBanco[5])

	ElseIf aDadosBanco[1] $ '422'
		cString := Alltrim(PADR(CValToChar(Val(aDadosBanco[3])),5,"0")+"/"+aDadosBanco[4]+aDadosBanco[5])

	Else
		cString := Alltrim(aDadosBanco[3]+iif(!Empty(aDadosBanco[10]),"-"+aDadosBanco[10],"")) +"/"+aDadosBanco[4]
	EndIf

	nCol := 1860+(374-(len(cString)*22))

	If lImpTela // Impressão em Tela
		oPrint:Say(nRowSay+0865,nCol,cString,oFont11c)
	Else
		oPrint:Say(nRowSay+0860,nCol,cString,oFont11c)
	EndIf

	If lImpTela // Impressão em Tela

		oPrint:Say(nRowSay+0905,100 ,"Data do Documento",oFont8)
		oPrint:Say(nRowSay+0935,100, StrZero(Day((aDadosTit[2])),2) +"/"+ StrZero(Month((aDadosTit[2])),2) +"/"+ Right(Str(Year((aDadosTit[2]))),4),oFont10n)

		oPrint:Say(nRowSay+0905,505 ,"Nro.Documento",oFont8)
		oPrint:Say(nRowSay+0935,605 ,aDadosTit[7]+aDadosTit[1],oFont10n) //Prefixo +Numero+Parcela

		oPrint:Say(nRowSay+0905,1005,"Espécie Doc.",oFont8)
		oPrint:Say(nRowSay+0935,1050,aDadosTit[8],oFont10n) //Tipo do Titulo

		oPrint:Say(nRowSay+0905,1305,"Aceite",oFont8)
		oPrint:Say(nRowSay+0935,1400,"N",oFont10n)

		oPrint:Say(nRowSay+0905,1485,"Data do Processamento",oFont8)
		oPrint:Say(nRowSay+0935,1550,StrZero(Day((aDadosTit[3])),2) +"/"+ StrZero(Month((aDadosTit[3])),2) +"/"+ Right(Str(Year((aDadosTit[3]))),4),oFont10n) // Data impressao

		oPrint:Say(nRowSay+0905,1810,"Nosso Número",oFont8)
	Else

		oPrint:Say(nRowSay+0895,100 ,"Data do Documento",oFont8)
		oPrint:Say(nRowSay+0930,100, StrZero(Day((aDadosTit[2])),2) +"/"+ StrZero(Month((aDadosTit[2])),2) +"/"+ Right(Str(Year((aDadosTit[2]))),4),oFont10n)

		oPrint:Say(nRowSay+0895,505 ,"Nro.Documento",oFont8)
		oPrint:Say(nRowSay+0930,605 ,aDadosTit[7]+aDadosTit[1],oFont10n) //Prefixo +Numero+Parcela

		oPrint:Say(nRowSay+0895,1005,"Espécie Doc.",oFont8)
		oPrint:Say(nRowSay+0930,1050,aDadosTit[8],oFont10n) //Tipo do Titulo

		oPrint:Say(nRowSay+0895,1305,"Aceite",oFont8)
		oPrint:Say(nRowSay+0930,1400,"N",oFont10n)

		oPrint:Say(nRowSay+0895,1485,"Data do Processamento",oFont8)
		oPrint:Say(nRowSay+0930,1550,StrZero(Day((aDadosTit[3])),2) +"/"+ StrZero(Month((aDadosTit[3])),2) +"/"+ Right(Str(Year((aDadosTit[3]))),4),oFont10n) // Data impressao

		oPrint:Say(nRowSay+0895,1810,"Nosso Número",oFont8)
	EndIf

	If aDadosBanco[1] == '001'
		cString := SubStr(aDadosTit[6],1,3) + Substr(aDadosTit[6],4) + iif( Len(AllTrim(SEE->EE_CODEMP))>=7,"", "-" + SE1->E1_XDVNNUM)
	Else
		cString := SubStr(aDadosTit[6],1,3)+Substr(aDadosTit[6],4)
	EndIf

	nCol := 1850+(374-(len(cString)*22))

	If lImpTela // Impressão em Tela
		oPrint:Say(nRowSay+0935,nCol,cString,oFont11c)
	Else
		oPrint:Say(nRowSay+0930,nCol,cString,oFont11c)
	EndIf

	If lImpTela // Impressão em Tela

		oPrint:Say(nRowSay+0980,100 ,"Uso do Banco" ,oFont8)

		oPrint:Say(nRowSay+0980,505 ,"Carteira" ,oFont8)
		oPrint:Say(nRowSay+1010,555 ,aDadosBanco[6] ,oFont10n)

		oPrint:Say(nRowSay+0980,755 ,"Espécie" ,oFont8)
		oPrint:Say(nRowSay+1010,805 ,"R$" ,oFont10n)

		oPrint:Say(nRowSay+0980,1005,"Quantidade" ,oFont8)
		oPrint:Say(nRowSay+0980,1485,"Valor" ,oFont8)

		oPrint:Say(nRowSay+0980,1810,"Valor do Documento" ,oFont8)
		cString := Alltrim(Transform(aDadosTit[10],"@E 99,999,999.99"))
		nCol := 1840 + (374 - (Len(cString) * 22))
		oPrint:Say(nRowSay+1005,nCol,cString ,oFont11c)
	Else
		oPrint:Say(nRowSay+0965,100 ,"Uso do Banco" ,oFont8)

		oPrint:Say(nRowSay+0965,505 ,"Carteira" ,oFont8)
		oPrint:Say(nRowSay+0998,555 ,aDadosBanco[6] ,oFont10n)

		oPrint:Say(nRowSay+0965,755 ,"Espécie" ,oFont8)
		oPrint:Say(nRowSay+0998,805 ,"R$" ,oFont10n)

		oPrint:Say(nRowSay+0965,1005,"Quantidade" ,oFont8)
		oPrint:Say(nRowSay+0965,1485,"Valor" ,oFont8)

		oPrint:Say(nRowSay+0965,1810,"Valor do Documento" ,oFont8)
		cString := Alltrim(Transform(aDadosTit[10],"@E 99,999,999.99"))
		nCol := 1840+(374-(len(cString)*22))
		oPrint:Say(nRowSay+1000,nCol,cString ,oFont11c)
	EndIf

	If AllTrim(SEE->EE_CODIGO) == "237"
		oPrint:Say(nRowSay+1050,100 ,"Instruções (Responsabilidade do Beneficiário ou Cedente)",oFont8)
	Else
		oPrint:Say(nRowSay+1050,100 ,"Instruções (Todas informações deste bloqueto são de exclusiva responsabilidade do beneficiário)",oFont8)
	EndIf

	If lImpTela // Impressão em Tela

		oPrint:Say(nRowSay+1090,100 ,aBolText[1],oFont10n)
		oPrint:Say(nRowSay+1140,100 ,aBolText[2],oFont10n)
		oPrint:Say(nRowSay+1190,100 ,aBolText[3],oFont10n)
		oPrint:Say(nRowSay+1240,100 ,aBolText[4],oFont10n)
		oPrint:Say(nRowSay+1290,100 ,aBolText[5],oFont10n)
		oPrint:Say(nRowSay+1340,100 ,aBolText[6],oFont10n)

		//Renegociação, extra Marajó
		If aDadosTit[7] == "REN" .And. !lMarajo
			oPrint:Say(nRowSay+1280,100 ,aBolText[7],oFont8)
		Else
			oPrint:Say(nRowSay+1280,100 ,aBolText[7],oFont10n)
		EndIf
	Else

		oPrint:Say(nRowSay+1100,100 ,aBolText[1],oFont10n)
		oPrint:Say(nRowSay+1140,100 ,aBolText[2],oFont10n)
		oPrint:Say(nRowSay+1190,100 ,aBolText[3],oFont10n)
		oPrint:Say(nRowSay+1240,100 ,aBolText[4],oFont10n)
		oPrint:Say(nRowSay+1290,100 ,aBolText[5],oFont10n)
		oPrint:Say(nRowSay+1290,100 ,aBolText[6],oFont10n)

		//Renegociação, extra Marajó
		If aDadosTit[7] == "REN" .And. !lMarajo
			oPrint:Say(nRowSay+1330,100 ,aBolText[7],oFont8)
		Else
			oPrint:Say(nRowSay+1330,100 ,aBolText[7],oFont10n)
		EndIf
	EndIf

// Mensagem dos Parâmetros
	If !Empty(MV_PAR21)
		oPrint:Say(nRowSay+1360,100, AllTrim(MV_PAR21) + " - " + AllTrim(MV_PAR22),oFont10n)
	EndIf

	If lImpTela // Impressão em Tela

		oPrint:Say(nRowSay+1050,1810,"(-)Desconto/Abatimento" ,oFont8)
		cString := Alltrim(Transform(aDadosTit[12],"@E 99,999,999.99"))
		nCol := 1840+(374-(len(cString)*22))
		oPrint:Say(nRowSay+1075,nCol,cString ,oFont11c)
		oPrint:Say(nRowSay+1120,1810,"(-)Outras Deduções" ,oFont8)
		oPrint:Say(nRowSay+1190,1810,"(+)Mora/Multa" ,oFont8)
		oPrint:Say(nRowSay+1260,1810,"(+)Outros Acréscimos" ,oFont8)
		cString := Alltrim(Transform(aDadosTit[11],"@E 99,999,999.99"))
		nCol := 1840+(374-(len(cString)*22))
		oPrint:Say(nRowSay+1275,nCol,cString ,oFont11c)
		oPrint:Say(nRowSay+1330,1810,"(=)Valor Cobrado" ,oFont8)
		cString := Alltrim(Transform(aDadosTit[5],"@E 99,999,999.99"))
		nCol := 1840+(374-(len(cString)*22))
		oPrint:Say(nRowSay+1355,nCol,cString ,oFont11c)
	Else

		oPrint:Say(nRowSay+1040,1810,"(-)Desconto/Abatimento" ,oFont8)
		cString := Alltrim(Transform(aDadosTit[12],"@E 99,999,999.99"))
		nCol := 1840+(374-(len(cString)*22))
		oPrint:Say(nRowSay+1070,nCol,cString ,oFont11c)
		oPrint:Say(nRowSay+1110,1810,"(-)Outras Deduções" ,oFont8)
		oPrint:Say(nRowSay+1180,1810,"(+)Mora/Multa" ,oFont8)
		oPrint:Say(nRowSay+1250,1810,"(+)Outros Acréscimos" ,oFont8)
		cString := Alltrim(Transform(aDadosTit[11],"@E 99,999,999.99"))
		nCol := 1840+(374-(len(cString)*22))
		oPrint:Say(nRowSay+1277,nCol,cString ,oFont11c)
		oPrint:Say(nRowSay+1320,1810,"(=)Valor Cobrado" ,oFont8)
		cString := Alltrim(Transform(aDadosTit[5],"@E 99,999,999.99"))
		nCol := 1840+(374-(len(cString)*22))
		oPrint:Say(nRowSay+1352,nCol,cString ,oFont11c)
	EndIf

	If aDadosTit[9] > 0 .and. aDadosTit[4] >= dDataBase
		cString := Alltrim(Transform( aDadosTit[9],"@E 999,999,999.99"))
		nCol := 1810+(374-(len(cString)*22))
		oPrint:Say(nRowSay+1080,nCol,cString,oFont11c)
	EndIf

	oPrint:Say(nRowSay+1400,100 ,"Pagador",oFont8)

	oPrint:Say(nRowSay+1405,400 ,aDatSacado[1]+" ("+aDatSacado[2]+")" ,oFont10n)
	oPrint:Say(nRowSay+1445,400 ,aDatSacado[3] ,oFont10n)
	oPrint:Say(nRowSay+1485,400 ,aDatSacado[6]+" "+aDatSacado[4]+" - "+aDatSacado[5],oFont10n) // CEP+Cidade+Estado

	If AllTrim(SEE->EE_CODIGO) <> "422"
		If aDatSacado[8] = "J"
			oPrint:Say(nRowSay+1560,400 ,"CNPJ: "+TRANSFORM(aDatSacado[7],"@R 99.999.999/9999-99"),oFont10n) // CGC
		Else
			oPrint:Say(nRowSay+1560,400 ,"CPF: "+TRANSFORM(aDatSacado[7],"@R 999.999.999-99"),oFont10n) 	// CPF
		EndIf
	endif

	oPrint:Say(nRowSay+1560,100 ,"Sacador/Avalista",oFont8)
	oPrint:Say(nRowSay+1610,1680,"Autenticação Mecânica Recibo do Pagador",oFont8)

	If lImpTela // Impressão em Tela
		MSBAR3("INT25"/*cTypeBar*/,14.5/*nRow*/,0.9/*nCol*/,aCB_RN_NN[1]/*cCode*/,oPrint/*oPrint*/,.F./*lCheck*/,/*Color*/,.T./*lHorz*/,0.030/*nWidth*/,1.3/*nHeigth*/,/*lBanner*/,/*cFont*/,/*cMode*/,.F./*lPrint*/,/*nPFWidth*/,/*nPFHeigth*/,/*lCmtr2Pix*/)
	Else
		oPrint:FwMsBar("INT25" /*cTypeBar*/, 38.5 /*nRow*/, 2.40 /*nCol*/,aCB_RN_NN[1] /*cCode*/, oPrint, .F. /*Calc6. Digito Verif*/,/*Color*/, /*Imp. na Horz*/, 0.025 /*Tamanho*/, 0.85 /*Altura*/, , , ,.F. )
	EndIf

	oPrint:Line(nRow2+0710,1800,nRow2+1400,1800)
	oPrint:Line(nRow2+1120,1800,nRow2+1120,2300)
	oPrint:Line(nRow2+1190,1800,nRow2+1190,2300)
	oPrint:Line(nRow2+1260,1800,nRow2+1260,2300)
	oPrint:Line(nRow2+1330,1800,nRow2+1330,2300)
	oPrint:Line(nRow2+1400,100 ,nRow2+1400,2300)
	oPrint:Line(nRow2+1610,100 ,nRow2+1610,2300)

/******************/
/* TERCEIRA PARTE */
/******************/

	If lImpTela // Impressão em Tela
		nRow3 := 55
	Else
		nRow3   := -80
	EndIf

	For nI := 100 to 2300 step 50
		oPrint:Line(nRow3+1860, nI, nRow3+1860, nI+30)
	Next nI

	If lImpTela // Impressão em Tela
		nRowSay := 30
		nRow3   := 30
	Else
		nRowSay := -85
		nRow3   := -110
	EndIf

	oPrint:Line (nRow3+2000,100,nRow3+2000,2300)
	oPrint:Line (nRow3+2000,500,nRow3+1920, 500)
	oPrint:Line (nRow3+2000,710,nRow3+1920, 710)

	If lImpTela // Impressão em Tela

		If AllTrim(SEE->EE_CODIGO) == "033"
			oPrint:SayBitmap(nRow1+1875,100,cStartPath+"santander.jpg",400,090)

		ElseIf AllTrim(SEE->EE_CODIGO) == "422"
			//oPrint:SayBitmap(nRow1+1875,100,cStartPath+"safra.jpg",400,090)
			oPrint:Say(nRow1+1905,100,aDadosBanco[2] ,oFont10 )

		ElseIf AllTrim(SEE->EE_CODIGO) == "237"
			oPrint:SayBitmap(nRow1+1875,100,cStartPath+"bradesco.jpg",390,095)

		ElseIf AllTrim(SEE->EE_CODIGO) == "341"

			If lMarajo
				oPrint:SayBitmap(nRow1+1730,100,cStartPath+"itau.jpg",400,100)
			Else
				oPrint:SayBitmap(nRow1+1730,100,cStartPath+"itau.jpg",120,100)
			EndIf

		ElseIf AllTrim(SEE->EE_CODIGO) == "756"
			oPrint:SayBitmap(nRow1+1875,100,cStartPath+"sicoob_logo.jpg",395,090)

		ElseIf AllTrim(SEE->EE_CODIGO) == "001"
			oPrint:SayBitmap(nRow1+1875,100,cStartPath+"bb2.jpg",400,090)

		Else
			oPrint:Say(nRowSay+1940,100,aDadosBanco[2],oFont12 )
		EndIf
	Else

		If AllTrim(SEE->EE_CODIGO) == "033"
			oPrint:SayBitmap(nRow1+1812,100,cStartPath+"santander.jpg",400,075)

		ElseIf AllTrim(SEE->EE_CODIGO) == "422"
			//oPrint:SayBitmap(nRow1+1812,100,cStartPath+"safra.jpg",400,075)
			oPrint:Say(nRow1+1842,100,aDadosBanco[2] ,oFont10 )

		ElseIf AllTrim(SEE->EE_CODIGO) == "237"
			oPrint:SayBitmap(nRow1+1812,100,cStartPath+"bradesco.jpg",390,080)

		ElseIf AllTrim(SEE->EE_CODIGO) == "341"

			If lMarajo
				oPrint:SayBitmap(nRow1+1807,100,cStartPath+"itau.jpg",400,085)
			Else
				oPrint:SayBitmap(nRow1+1807,100,cStartPath+"itau.jpg",120,085)
			EndIf

		ElseIf AllTrim(SEE->EE_CODIGO) == "756"
			oPrint:SayBitmap(nRow1+1812,100,cStartPath+"sicoob_logo.jpg",395,075)

		ElseIf AllTrim(SEE->EE_CODIGO) == "001"
			oPrint:SayBitmap(nRow1+1812,100,cStartPath+"bb2.jpg",400,075)

		Else
			oPrint:Say(nRowSay+1945,100,aDadosBanco[2],oFont12 )
		EndIf
	EndIf

	If lImpTela // Impressão em Tela
		oPrint:Say(nRowSay+1925,518,aDadosBanco[1]+"-"+aDadosBanco[7],oFont20 )	// [1]Numero do Banco
		oPrint:Say(nRowSay+1930,730,aCB_RN_NN[2],oFont14N) // Linha Digitavel do Codigo de Barras
	Else
		oPrint:Say(nRowSay+1945,518,aDadosBanco[1]+"-"+aDadosBanco[7],oFont20 )	// [1]Numero do Banco
		oPrint:Say(nRowSay+1940,730,aCB_RN_NN[2],oFont18) // Linha Digitavel do Codigo de Barras
	EndIf

	oPrint:Line(nRow3+2100,100,nRow3+2100,2300)
	oPrint:Line(nRow3+2200,100,nRow3+2200,2300)
	oPrint:Line(nRow3+2270,100,nRow3+2270,2300)
	oPrint:Line(nRow3+2340,100,nRow3+2340,2300)

	oPrint:Line(nRow3+2200,500 ,nRow3+2340,500)
	oPrint:Line(nRow3+2270,750 ,nRow3+2340,750)
	oPrint:Line(nRow3+2200,1000,nRow3+2340,1000)
	oPrint:Line(nRow3+2200,1300,nRow3+2270,1300)
	oPrint:Line(nRow3+2200,1480,nRow3+2340,1480)

	oPrint:Say(nRowSay+2000,100 ,"Local de Pagamento",oFont8)
	oPrint:Say(nRowSay+2020,400 ,aDadosBanco[8],oFont10n)
	oPrint:Say(nRowSay+2055,400 ,aDadosBanco[9],oFont10n)

	oPrint:Say(nRowSay+2000,1810,"Vencimento",oFont8)

	cString := StrZero(Day((aDadosTit[4])),2) +"/"+ StrZero(Month((aDadosTit[4])),2) +"/"+ Right(Str(Year((aDadosTit[4]))),4)
	nCol := 1850+(374-(len(cString)*22))
	oPrint:Say(nRowSay+2045,nCol,cString,oFont12)

	oPrint:Say(nRowSay+2100,100 ,"Beneficiário",oFont8)
	oPrint:Say(nRowSay+2140,100 ,alltrim(aDadosEmp[1])+" - "+alltrim(aDadosEmp[6])	,oFont10n) //Nome + CNPJ

	oPrint:Say(nRowSay+2100,1810,"Agência/Código Beneficiário",oFont8)

	If aDadosBanco[1] == '001'
		cString := Alltrim(aDadosBanco[3]+iif(!Empty(aDadosBanco[10]),"-"+aDadosBanco[10],"")+"/"+iif(Empty(aDadosBanco[11]),aDadosBanco[4]+"-"+aDadosBanco[5], aDadosBanco[12]))

	ElseIf aDadosBanco[1] $ '033/756'
		cString := Alltrim(aDadosBanco[3]+iif(!Empty(aDadosBanco[10]),"-"+aDadosBanco[10],"")+"/"+iif(Empty(aDadosBanco[11]),aDadosBanco[4]+"-"+aDadosBanco[5], aDadosBanco[11]))

	ElseIf aDadosBanco[1] $ '341'
		cString := Alltrim(aDadosBanco[3]+"/"+aDadosBanco[4]+"-"+aDadosBanco[5])
		
	ElseIf aDadosBanco[1] $ '422'
		cString := Alltrim(PADR(CValToChar(Val(aDadosBanco[3])),5,"0")+"/"+aDadosBanco[4]+aDadosBanco[5])

	ElseIf aDadosBanco[1] $ '237'
		cString := Alltrim(StrZero(Val(aDadosBanco[3]),4)+iif(!Empty(aDadosBanco[10]),"-"+aDadosBanco[10],"")+"/"+IIF(!EMPTY(aDadosBanco[5]),StrZero(Val(aDadosBanco[4]),7)+"-"+aDadosBanco[5],StrZero(Val(Left(aDadosBanco[4],len(aDadosBanco[4])-1)),7)+"-"+Right(aDadosBanco[4],1)))

	Else
		cString := Alltrim(aDadosBanco[3]+iif(!Empty(aDadosBanco[10]),"-"+aDadosBanco[10],"")) +"/"+aDadosBanco[4]
	EndIf

	nCol := 1830 + (374 - (Len(cString) * 22))
	oPrint:Say(nRowSay+2140,nCol,cString ,oFont11c)

	If lImpTela // Impressão em Tela

		oPrint:Say(nRowSay+2200,100 ,"Data do Documento" ,oFont8)
		oPrint:Say(nRowSay+2230,100, StrZero(Day((aDadosTit[2])),2) +"/"+ StrZero(Month((aDadosTit[2])),2) +"/"+ Right(Str(Year((aDadosTit[2]))),4), oFont10n)

		oPrint:Say(nRowSay+2200,505 ,"Nro.Documento" ,oFont8)
		oPrint:Say(nRowSay+2230,605 ,aDadosTit[7]+aDadosTit[1] ,oFont10n) // Prefixo+Numero+Parcela

		oPrint:Say(nRowSay+2200,1005,"Espécie Doc." ,oFont8)
		oPrint:Say(nRowSay+2230,1050,aDadosTit[8] ,oFont10n) //Tipo do Titulo

		oPrint:Say(nRowSay+2200,1305,"Aceite" ,oFont8)
		oPrint:Say(nRowSay+2230,1400,"N" ,oFont10n)

		oPrint:Say(nRowSay+2200,1485,"Data do Processamento" ,oFont8)
		oPrint:Say(nRowSay+2230,1550,StrZero(Day((aDadosTit[3])),2) +"/"+ StrZero(Month((aDadosTit[3])),2) +"/"+ Right(Str(Year((aDadosTit[3]))),4)                               ,oFont10n) // Data impressao

		oPrint:Say(nRowSay+2200,1810,"Nosso Número" ,oFont8)

		If aDadosBanco[1] == '001'
			cString := Substr(aDadosTit[6],1,3) + Substr(aDadosTit[6],4) + iif( Len(AllTrim(SEE->EE_CODEMP))>=7,"", "-" + SE1->E1_XDVNNUM)
		Else
			cString := Alltrim(Substr(aDadosTit[6],1,3)+Substr(aDadosTit[6],4))
		EndIf

		nCol := 1830 + (374 - (Len(cString) * 22))
		oPrint:Say(nRowSay+2230,nCol,cString,oFont11c)
	Else

		oPrint:Say(nRowSay+2180,100 ,"Data do Documento" ,oFont8)
		oPrint:Say(nRowSay+2215,100, StrZero(Day((aDadosTit[2])),2) +"/"+ StrZero(Month((aDadosTit[2])),2) +"/"+ Right(Str(Year((aDadosTit[2]))),4), oFont10n)

		oPrint:Say(nRowSay+2180,505 ,"Nro.Documento" ,oFont8)
		oPrint:Say(nRowSay+2215,605 ,aDadosTit[7]+aDadosTit[1] ,oFont10n) // Prefixo+Numero+Parcela

		oPrint:Say(nRowSay+2180,1005,"Espécie Doc." ,oFont8)
		oPrint:Say(nRowSay+2215,1050,aDadosTit[8] ,oFont10n) // Tipo do Titulo

		oPrint:Say(nRowSay+2180,1305,"Aceite" ,oFont8)
		oPrint:Say(nRowSay+2215,1400,"N" ,oFont10n)

		oPrint:Say(nRowSay+2180,1485,"Data do Processamento" ,oFont8)
		oPrint:Say(nRowSay+2215,1550,StrZero(Day((aDadosTit[3])),2) +"/"+ StrZero(Month((aDadosTit[3])),2) +"/"+ Right(Str(Year((aDadosTit[3]))),4)                               ,oFont10n) // Data impressao

		oPrint:Say(nRowSay+2180,1810,"Nosso Número" ,oFont8)

		If aDadosBanco[1] == '001'
			cString := Substr(aDadosTit[6],1,3) + Substr(aDadosTit[6],4) + iif( Len(AllTrim(SEE->EE_CODEMP))>=7,"", "-" + SE1->E1_XDVNNUM)
		Else
			cString := Alltrim(Substr(aDadosTit[6],1,3)+Substr(aDadosTit[6],4))
		EndIf

		nCol := 1830 + (374 - (Len(cString) * 22))
		oPrint:Say(nRowSay+2215,nCol,cString,oFont11c)
	EndIf

	If lImpTela // Impressão em Tela

		oPrint:Say(nRowSay+2270,100 ,"Uso do Banco",oFont8)

		oPrint:Say(nRowSay+2270,505 ,"Carteira",oFont8)
		oPrint:Say(nRowSay+2300,555 ,aDadosBanco[6] ,oFont10n)

		oPrint:Say(nRowSay+2270,755 ,"Espécie" ,oFont8)
		oPrint:Say(nRowSay+2300,805 ,"R$" ,oFont10n)

		oPrint:Say(nRowSay+2270,1005,"Quantidade" ,oFont8)
		oPrint:Say(nRowSay+2270,1485,"Valor" ,oFont8)

		oPrint:Say(nRowSay+2270,1810,"Valor do Documento" ,oFont8)
		cString := Alltrim(Transform(aDadosTit[10],"@E 99,999,999.99"))
		nCol := 1840 + (374 - (Len(cString) * 22))
		oPrint:Say(nRowSay+2300,nCol-20,cString,oFont11c)
	Else

		oPrint:Say(nRowSay+2255,100 ,"Uso do Banco" ,oFont8)

		oPrint:Say(nRowSay+2255,505 ,"Carteira" ,oFont8)
		oPrint:Say(nRowSay+2290,555 ,aDadosBanco[6] ,oFont10n)

		oPrint:Say(nRowSay+2255,755 ,"Espécie" ,oFont8)
		oPrint:Say(nRowSay+2290,805 ,"R$" ,oFont10n)

		oPrint:Say(nRowSay+2255,1005,"Quantidade" ,oFont8)
		oPrint:Say(nRowSay+2255,1485,"Valor" ,oFont8)

		oPrint:Say(nRowSay+2255,1810,"Valor do Documento" ,oFont8)
		cString := Alltrim(Transform(aDadosTit[10],"@E 99,999,999.99"))
		nCol := 1840 + (374 - (Len(cString) * 22))
		oPrint:Say(nRowSay+2290,nCol-20,cString,oFont11c)
	EndIf

	If AllTrim(SEE->EE_CODIGO) == "237"
		oPrint:Say(nRowSay+2340,100 ,"Instruções (Responsabilidade do Beneficiário ou Cedente)",oFont8)
	Else
		oPrint:Say(nRowSay+2340,100 ,"Instruções (Todas informações deste bloqueto são de exclusiva responsabilidade do Beneficiário)",oFont8)
	EndIf

	oPrint:Say(nRowSay+2320,100 ,aBolText[1],oFont10n)
	oPrint:Say(nRowSay+2445,100 ,aBolText[2],oFont10n)
	oPrint:Say(nRowSay+2495,100 ,aBolText[3],oFont10n)
	oPrint:Say(nRowSay+2545,100 ,aBolText[4],oFont10n)
	oPrint:Say(nRowSay+2595,100 ,aBolText[5],oFont10n)
	oPrint:Say(nRowSay+2595,100 ,aBolText[6],oFont10n)

// Renegociação, extra Marajó
	If aDadosTit[7] == "REN" .And. !lMarajo
		oPrint:Say(nRowSay+2635,100 ,aBolText[7],oFont8)
	Else
		oPrint:Say(nRowSay+2635,100 ,aBolText[7],oFont10n)
	EndIf

// Diferente de Marajó
	If !lMarajo

		If _cont = 1 .and. Empty(aBolText[4]+aBolText[5])
			oPrint:Say(nRowSay+2628,100 ,"/////ATENÇÃO/////--> SEGUNDA VIA",oFont10n)
		EndIf
	EndIf

// Mensagens parâmetros
	If !Empty(MV_PAR21)
		oPrint:Say(nRowSay+2640,100 ,AllTrim(MV_PAR21) + " - " + AllTrim(MV_PAR22),oFont10n)
	EndIf

	If lImpTela // Impressão em Tela

		oPrint:Say(nRowSay+2340,1810,"(-)Desconto/Abatimento" ,oFont8)
		cString := Alltrim(Transform(aDadosTit[12],"@E 99,999,999.99"))
		nCol := 1840+(374-(len(cString)*22))
		oPrint:Say(nRowSay+2365,nCol,cString ,oFont11c)
		oPrint:Say(nRowSay+2410,1810,"(-)Outras Deduções" ,oFont8)
		oPrint:Say(nRowSay+2480,1810,"(+)Mora/Multa" ,oFont8)
		oPrint:Say(nRowSay+2550,1810,"(+)Outros Acréscimos" ,oFont8)
		cString := Alltrim(Transform(aDadosTit[11],"@E 99,999,999.99"))
		nCol := 1840+(374-(len(cString)*22))
		oPrint:Say(nRowSay+2575,nCol,cString ,oFont11c)
		oPrint:Say(nRowSay+2620,1810,"(=)Valor Cobrado" ,oFont8)
		cString := Alltrim(Transform(aDadosTit[5],"@E 99,999,999.99"))
		nCol := 1840+(374-(len(cString)*22))
		oPrint:Say(nRowSay+2645,nCol,cString,oFont11c)
	Else

		oPrint:Say(nRowSay+2330,1810,"(-)Desconto/Abatimento" ,oFont8)
		cString := Alltrim(Transform(aDadosTit[12],"@E 99,999,999.99"))
		nCol := 1840+(374-(len(cString)*22))
		oPrint:Say(nRowSay+2355,nCol,cString,oFont11c)
		oPrint:Say(nRowSay+2400,1810,"(-)Outras Deduções" ,oFont8)
		oPrint:Say(nRowSay+2470,1810,"(+)Mora/Multa" ,oFont8)
		oPrint:Say(nRowSay+2540,1810,"(+)Outros Acréscimos" ,oFont8)
		cString := Alltrim(Transform(aDadosTit[11],"@E 99,999,999.99"))
		nCol := 1840+(374-(len(cString)*22))
		oPrint:Say(nRowSay+2570,nCol,cString ,oFont11c)
		oPrint:Say(nRowSay+2610,1810,"(=)Valor Cobrado" ,oFont8)
		cString := Alltrim(Transform(aDadosTit[5],"@E 99,999,999.99"))
		nCol := 1840 + (374 - (Len(cString) * 22))
		oPrint:Say(nRowSay+2635,nCol,cString,oFont11c)
	EndIf

	oPrint:Say(nRowSay+2690,100 ,"Pagador",oFont8)
	oPrint:Say(nRowSay+2700,400 ,aDatSacado[1]+" ("+aDatSacado[2]+")" ,oFont10n)
	oPrint:Say(nRowSay+2743,400 ,aDatSacado[3] ,oFont10n)
	oPrint:Say(nRowSay+2786,400 ,aDatSacado[6]+" "+aDatSacado[4]+" - "+aDatSacado[5],oFont10n) // CEP+Cidade+Estado

	If aDadosTit[9] > 0  .And. aDadosTit[4] >= dDataBase
		cString := Alltrim(Transform(aDadosTit[9],"@E 999,999,999.99"))
		nCol := 1810 + (374 - (Len(cString) * 22))
		oPrint:Say(nRowSay+2370,nCol,cString,oFont11c)
	EndIf

	oPrint:Say  (nRow3+2875,100 ,"Sacador/Avalista" ,oFont8)
	If AllTrim(SEE->EE_CODIGO) <> "422"
		If aDatSacado[8] = "J"
			oPrint:Say(nRowSay+2870,400 ,"CNPJ: "+Transform(aDatSacado[7],"@R 99.999.999/9999-99"),oFont10n) // CGC
		Else
			oPrint:Say(nRowSay+2870,400 ,"CPF: "+Transform(aDatSacado[7],"@R 999.999.999-99"),oFont10n) 	// CPF
		EndIf
	endif

	oPrint:Line(nRow3+2000,1800,nRow3+2690,1800)
	oPrint:Line(nRow3+2410,1800,nRow3+2410,2300)
	oPrint:Line(nRow3+2480,1800,nRow3+2480,2300)
	oPrint:Line(nRow3+2550,1800,nRow3+2550,2300)
	oPrint:Line(nRow3+2620,1800,nRow3+2620,2300)
	oPrint:Line(nRow3+2690,100 ,nRow3+2690,2300)
	oPrint:Line(nRow3+2920,100 ,nRow3+2920,2300)

	If aDadosBanco[1] $ '237'
		oPrint:Say(nRowSay+2915,1800,"Autenticação Mecânica - Ficha de Compensação"   ,oFont8)
	Else
		oPrint:Say(nRowSay+2915,1680,"Autenticação Mecânica - Ficha de Compensação"   ,oFont8)
	EndIf

	If lImpTela // Impressão em Tela
		MSBAR3("INT25"/*cTypeBar*/,25.5/*nRow*/,0.9/*nCol*/,aCB_RN_NN[1]/*cCode*/,oPrint/*oPrint*/,.F./*lCheck*/,/*Color*/,.T./*lHorz*/,0.030/*nWidth*/,1.3/*nHeigth*/,/*lBanner*/,/*cFont*/,/*cMode*/,.F./*lPrint*/,/*nPFWidth*/,/*nPFHeigth*/,/*lCmtr2Pix*/)
	Else
		oPrint:FwMsBar("INT25" /*cTypeBar*/, 66.5 /*nRow*/, 2.40 /*nCol*/,aCB_RN_NN[1] /*cCode*/, oPrint, .F. /*Calc6. Digito Verif*/,/*Color*/, /*Imp. na Horz*/, 0.025 /*Tamanho*/, 0.85 /*Altura*/, , , ,.F. )
	EndIf

	oPrint:EndPage() // Finaliza a página

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} Ret_cBarra
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function Ret_cBarra(	cPrefixo	,cNumero	,cParcela	,cTipo	,;
		cBanco		,cAgencia	,cConta		,cDacCC	,;
		cNroDoc		,nValor		,cCart		,cMoeda	)

	Local cNosso		:= ""
	Local cCampoL		:= ""
	Local cFatorValor	:= ""
	Local cLivre		:= ""
	Local cDigBarra		:= ""
	Local cBarra		:= ""
	Local cParte1		:= ""
	Local cDig1			:= ""
	Local cParte2		:= ""
	Local cDig2			:= ""
	Local cParte3		:= ""
	Local cDig3			:= ""
	Local cParte4		:= ""
	Local cParte5		:= ""
	Local cDigital		:= ""
	Local cTexto        := ""
	Local aRet			:= {}

	cAgencia := StrZero(Val(cAgencia),4)
	cNosso   := ""

	If cBanco == '001' .and. len( AllTrim(_cConvenio) ) == 6 // Banco do Brasil

		// Convênio 6 posições
		cConta	   := StrZero( val(cConta),8)
		cNosso     := _cConvenio + cNroDoc
		cDigNosso  := CALC_di9(cNosso)
		cCart      := cCart

		If nValor > 0
			cFatorValor  := fator()+strzero(nValor*100,10)
		Else
			cFatorValor  := fator()+strzero(SE1->E1_SALDO*100,10)
		EndIf

		// Campo livre
		cCampoL    := _cConvenio + cNroDoc + cAgencia + cConta + cCart

		// Campo do digito verificador do codigo de barra
		cLivre := cBanco+cMoeda+cFatorValor+cCampoL
		cDigBarra := CALC_5p( cLivre )

		// Campo do codigo de barra
		cBarra    := Substr(cLivre,1,4)+cDigBarra+Substr(cLivre,5,40)

		// Composicao da linha digitavel
		cParte1  := cBanco + cMoeda + Substr(_cConvenio,1,5)
		cDig1    := DIGIT001( cParte1 )
		cParte1  := cParte1 + cDig1

		cParte2  := SUBSTR(cCampoL,6,10) // cNroDoc + cAgencia
		cDig2    := DIGIT001( cParte2 )
		cParte2  := cParte2 + cDig2

		cParte3  := SUBSTR(cCampoL,16,10)
		cDig3    := DIGIT001( cParte3 )
		cParte3  := cParte3 + cDig3

		cParte4  := cDigBarra
		cParte5  := cFatorValor

		cDigital :=  substr(cParte1,1,5)+"."+substr(cparte1,6,5)+" "+;
			SubStr(cParte2,1,5)+"."+substr(cparte2,6,6)+" "+;
			SubStr(cParte3,1,5)+"."+substr(cparte3,6,6)+" "+;
			cParte4+" "+;
			cParte5

		AAdd(aRet,cBarra)
		AAdd(aRet,cDigital)
		AAdd(aRet,cNosso)

	ElseIf cBanco == '001' .and. Len(AllTrim(_cConvenio)) == 7

		// Convênio 7 posições
		cNosso     := StrZero(Val(_cConvenio),7)+StrZero(Val(cNroDoc),10)
		cDigNosso  := ""
		cCart      := cCart

		// Campo livre
		cCampoL    := StrZero(Val(_cConvenio),13)+strzero(Val(cNroDoc),10)+cCart

		// Campo livre do codigo de barra
		If nValor > 0
			cFatorValor  := fator()+strzero(nValor*100,10)
		Else
			cFatorValor  := fator()+strzero(SE1->E1_SALDO*100,10)
		EndIf

		// Campo do digito verificador do codigo de barra
		cLivre := cBanco+cMoeda+cFatorValor+cCampoL
		cDigBarra := CALC_5p( cLivre )

		// Campo do codigo de barra
		cBarra    := Substr(cLivre,1,4)+cDigBarra+Substr(cLivre,5,40)

		// Composicao da linha digitavel
		cParte1  := cBanco+cMoeda+Strzero(val(Substr(cBarra,4,1)),6)
		cDig1    := DIGIT001( cParte1 )

		cParte2  := SubStr(cCampoL,6,10)
		cDig2    := DIGIT001( cParte2 )
		cParte2  := cParte2 + cDig2

		cParte3  := SubStr(cCampoL,16,10)
		cDig3    := DIGIT001( cParte3 )
		cParte3  := cParte3 + cDig3

		cParte4  := cDigBarra
		cParte5  := cFatorValor

		cDigital :=  SubStr(cParte1,1,5)+"."+SubStr(cparte1,6,5)+" "+;
			SubStr(cParte2,1,5)+"."+SubStr(cparte2,6,6)+" "+;
			SubStr(cParte3,1,5)+"."+SubStr(cparte3,6,6)+" "+;
			cParte4+" "+;
			cParte5

		AAdd(aRet,cBarra)
		AAdd(aRet,cDigital)
		AAdd(aRet,cNosso)

	ElseIf cBanco == '341' // Itau

		If cCart $ '126/131/146/150/168'
			cTexto := cCart + cNroDoc
		Else
			cTexto := cAgencia + cConta + cCart + cNroDoc
		EndIf

		cTexto2 := cAgencia + cConta

		cDigCC  := Modu10(cTexto2)

		cNosso    := cCart + '/' + cNroDoc + '-' + cDigNosso
		cCart     := cCart

		If nValor > 0
			cFatorValor  := fator()+strzero(nValor*100,10)
		Else
			cFatorValor  := fator()+strzero(SE1->E1_SALDO*100,10)
		EndIf

		cValor:= StrZero(nValor * 100, 10)

		// Calculo do codigo de barras
		cCdBarra:= cBanco + cMoeda + cFatorValor + AllTrim(cCart) + cNroDoc + cDigNosso + cAgencia + cConta + cDigCC + "000"
		cDigCdBarra:= Modu11(cCdBarra,9)
		cCdBarra := Left(cCdBarra,4) + cDigCdBarra + Substr(cCdBarra,5,40)

		// Calculo da representacao numerica
		cCampo1:= cBanco+cMoeda+Substr(cCdBarra,20,5)
		cCampo2:= Substr(cCdBarra,25,10)
		cCampo3:= Substr(cCdBarra,35,10)

		cCampo4:= Substr(cCdBarra, 5, 1)
		cCampo5:= cFatorValor

		// Calculando os DACs dos campos 1, 2 e 3
		cCampo1:= cCampo1 + Modu10(cCampo1)
		cCampo2:= cCampo2 + Modu10(cCampo2)
		cCampo3:= cCampo3 + Modu10(cCampo3)

		cRepNum := Substr(cCampo1, 1, 5) + "." + Substr(cCampo1, 6, 5) + "  "
		cRepNum += Substr(cCampo2, 1, 5) + "." + Substr(cCampo2, 6, 6) + "  "
		cRepNum += Substr(cCampo3, 1, 5) + "." + Substr(cCampo3, 6, 6) + "  "
		cRepNum += cCampo4 + "  "
		cRepNum += cCampo5

		AAdd(aRet,cCdBarra)
		AAdd(aRet,cRepNum)
		AAdd(aRet,cNosso)

	ElseIf cBanco == '237' // Bradesco

		cNosso     := cCart + '/' + cNroDoc + '-' + cDigNosso

		// Ajuste feito para atender o cliente New Line
		_cConta := AllTrim(cConta)+AllTrim(cDacCC)
		_cConta := Left(_cConta,len(_cConta)-1)

		// Campo livre
		cCampoL    := cAgencia+cCart+cNroDoc+StrZero(Val(_cConta),7)+'0'

		// Campo livre do codigo de barra
		If nValor > 0
			cFatorValor  := fator()+strzero(nValor*100,10)
		Else
			cFatorValor  := fator()+strzero(SE1->E1_SALDO*100,10)
		EndIf

		// Campo do digito verificador do codigo de barra
		cLivre := cBanco+cMoeda+cFatorValor+cCampoL

		cDigBarra := CALC_5p( cLivre )

		// Campo do codigo de barra
		cBarra    := Substr(cLivre,1,4)+cDigBarra+Substr(cLivre,5,40)

		// Composicao da linha digitavel
		cParte1  := cBanco+cMoeda+Substr(cBarra,20,5)
		cDig1    :=  Modu10( cParte1 )
		cParte1  := cParte1 + cDig1

		cParte2  := SubStr(cBarra,25,10)
		cDig2    :=  Modu10( cParte2 )
		cParte2  := cParte2 + cDig2

		cParte3  := SubStr(cBarra,35,10)
		cDig3    :=  Modu10( cParte3 )
		cParte3  := cParte3 + cDig3

		cParte4  := cDigBarra
		cParte5  := cFatorValor

		cDigital :=  SubStr(cParte1,1,5)+"."+SubStr(cparte1,6,5)+" "+;
			SubStr(cParte2,1,5)+"."+SubStr(cparte2,6,6)+" "+;
			SubStr(cParte3,1,5)+"."+SubStr(cparte3,6,6)+" "+;
			cParte4+" "+;
			cParte5

		AAdd(aRet,cBarra)
		AAdd(aRet,cDigital)
		AAdd(aRet,cNosso)

	ElseIf cBanco == '033' 	// Santander

		cNosso    := cNroDoc + '-' + cDigNosso

		// Campo livre do codigo de barra
		If nValor > 0
			cFatorValor  := fator()+strzero(nValor*100,10)
		Else
			cFatorValor  := fator()+strzero(SE1->E1_SALDO*100,10)
		EndIf

		cBarra := cBanco 										//Codigo do banco na camara de compensacao
		cBarra += cMoeda  										//Codigo da Moeda
		cBarra += Fator()						  	    		//Fator Vencimento
		cBarra += strzero(nValor*100,10)						//Strzero(Round(SE1->E1_SALDO,2)*100,10)
		cBarra += "9"                                           //Sistema - Fixo
		cBarra += _cConvenio									//Código Cedente
		cBarra += cNroDoc + cDigNosso							//Nosso numero
		cBarra += "0"											//IOS
		cBarra += "101"/*Carteira*/						     	//Tipo de Cobrança

		cDigBarra := Modu11(cBarra)								//DAC codigo de barras

		cBarra := SubStr(cBarra,1,4) + cDigBarra + SubStr(cBarra,5,39)

		// Composicao da linha digitavel  1 PARTE DE 1
		cParte1 := cBanco 		 				     			//Codigo do banco na camara de compensacao
		cParte1 += cMoeda										//Cod. Moeda
		cParte1 += "9"											//Fixo "9" conforme manual Santander
		cParte1 += SubStr(_cConvenio,1,4)						//Código do Cedente (Posição 1 a 4)

		cDig1 := SubStr(cParte1,1,9)                  			//Pega variavel sem o '.'

		cParte1 += Modu10(cDig1)				  	    		//Digito verificador do campo


		// Composicao da linha digitavel 1 PARTE DE 2
		cParte2 := SubStr(_cConvenio,5,3)						//Código do Cedente (Posição 5 a 7)
		cParte2 += SubStr(cNroDoc + cDigNosso,1,7)				//Nosso Numero (Posição 1 a 7)

		cDig2 := SubStr(cParte2,1,10)							//Pega variavel sem o '.'

		cParte2 += Modu10(cDig2)					    		//Digito verificador do campo


		// Composicao da linha digitavel 2 PARTE DE 1
		cParte3 := SubStr(cNroDoc + cDigNosso,8,6)  			//Nosso Numero (Posição 8 a 13)
		cParte3 +="0"											//IOS (Fixo "0")
		cParte3 +="101"/*_cCarteira*/							//Tipo Cobrança (101-Cobrança Simples Rápida Com Registro)

		cDig3 := SubStr(cParte3,1,10) 			        		//Pega variavel sem o '.'

		cParte3 += Modu10(cDig3)				     			//Digito verificador do campo


		// Composicao da linha digitavel 4 PARTE
		cParte4 := SubStr(cBarra,5,1)							//Digito Verificador do Código de Barras


		// Composicao da linha digitavel 5 PARTE
		cParte5 := Fator()										//Fator de vencimento
		cParte5 += strzero(nValor*100,10)						//Valor do titulo (Saldo no E1)

		cDigital :=  SubStr(cParte1,1,5)+"."+SubStr(cparte1,6,5)+" "+;
			substr(cParte2,1,5)+"."+SubStr(cparte2,6,6)+" "+;
			substr(cParte3,1,5)+"."+SubStr(cparte3,6,6)+" "+;
			cParte4+" "+cParte5

		AAdd(aRet,cBarra)
		AAdd(aRet,cDigital)
		AAdd(aRet,cNosso)

	ElseIf cBanco == '422' // Safra

		cAgencia:=PADR(CValToChar(Val(cAgencia)),5,"0")
		cConta  :=STRZERO(Val(cConta),8)

		cNosso := cNroDoc + '-' + cDigNosso

		// Campo livre do codigo de barra
		If nValor > 0
			cFatorValor  := fator()+strzero(nValor*100,10)
		Else
			cFatorValor  := fator()+strzero(SE1->E1_SALDO*100,10)
		EndIf

		cBarra := cBanco 										//Codigo do banco na camara de compensacao
		cBarra += cMoeda  										//Codigo da Moeda
		cBarra += Fator()						  	    		//Fator Vencimento
		cBarra += strzero(nValor*100,10)						//Strzero(Round(SE1->E1_SALDO,2)*100,10)
		cBarra += "7"                                           //Sistema - Fixo
		//cBarra += cAgencia+alltrim(cDigAg)						//Agencia do cliente safra
		//cBarra += strzero(val(alltrim(cConta)),9)//conta do cliente
		cBarra += cAgencia
		cBarra += cConta + cDacCC
		cBarra += cNroDoc+cDigNosso								//Nosso numero
		cBarra += "2"/*Carteira*/					     		//Tipo de Cobrança

		cDigBarra := Modu11(cBarra)								//DAC codigo de barras

		cBarra := SubStr(cBarra,1,4) + cDigBarra + SubStr(cBarra,5,39)

		// composicao da linha digitavel  1 PARTE DE 1
		cParte1 := cBanco 		 				     			//Codigo do banco na camara de compensacao
		cParte1 += cMoeda										//Cod. Moeda
		cParte1 += "7"											//Fixo "9" conforme manual Santander
		cParte1 += Substr(cAgencia,1,4)							//4 primeiro digitos no numero da agencia (Posição 1 a 4)

		cDig1 := Substr(cParte1,1,9)                  			//Pega variavel sem o '.'

		cParte1 += Modu10(cDig1)				  	    		//Digito verificador do campo


		// Composicao da linha digitavel 1 PARTE DE 2
		//cParte2 := alltrim(cDigAg)								//ultimo digito da agencia
		//cParte2 += strzero(val(alltrim(cConta)),9)				//codigo do cliente
		cParte2 := Substr(cAgencia,5,1)								//ultimo digito da agencia
		cParte2 += cConta + cDacCC									//conta e digito da conta

		cDig2 := Substr(cParte2,1,10)							//Pega variavel sem o '.'

		cParte2 += Modu10(cDig2)					    		//Digito verificador do campo


		// Composicao da linha digitavel 2 PARTE DE 1
		cParte3 := cNroDoc+cDigNosso				  			//Nosso Numero
		cParte3 +="2"											//IOS (Fixo "0")

		cDig3 := Substr(cParte3,1,10) 			       			 //Pega variavel sem o '.'

		cParte3 += Modu10(cDig3)				     			//Digito verificador do campo

		// Composicao da linha digitavel 4 PARTE
		cParte4 := SubStr(cBarra,5,1)							//Digito Verificador do Código de Barras

		// composicao da linha digitavel 5 PARTE
		cParte5 := Fator()							//Fator de vencimento
		cParte5 += strzero(nValor*100,10)			//Valor do titulo (Saldo no E1)

		cDigital :=  SubStr(cParte1,1,5)+"."+substr(cparte1,6,5)+" "+;
			SubStr(cParte2,1,5)+"."+SubStr(cparte2,6,6)+" "+;
			SubStr(cParte3,1,5)+"."+SubStr(cparte3,6,6)+" "+;
			cParte4+" "+cParte5

		AAdd(aRet,cBarra)
		AAdd(aRet,cDigital)
		AAdd(aRet,cNosso)

	ElseIf cBanco == '756' // Sicoob

		cConta	:= StrZero(Val(cConta),8)
		cNosso	:= cNroDoc + '-' + cDigNosso
		cCart	:= cCart

		// Campo livre do codigo de barra
		If nValor > 0
			cFatorValor  := fator()+strzero(nValor*100,10)
		Else
			cFatorValor  := fator()+strzero(SE1->E1_SALDO*100,10)
		EndIf

		cBarra := cBanco 										//Codigo do banco na camara de compensacao
		cBarra += cMoeda  										//Codigo da Moeda
		cBarra += Fator()						  	    		//Fator Vencimento
		cBarra += strzero(nValor*100,10)						//Strzero(Round(SE1->E1_SALDO,2)*100,10)
		cBarra += "1"			                                //Sistema - Fixo
		cBarra += cAgencia										//Agencia do cliente safra
		cBarra += strzero(Val(alltrim(cCart)),2)				//modalidade(carteira)
		cBarra += StrZero(Val(_cConvenio),7)					//convencio
		cBarra += cNroDoc+cDigNosso								//Nosso numero
		cBarra += IIf(Empty(se1->e1_parcela),"001",(StrZero(Val(se1->e1_parcela),3)))		     	//Parcela do Boleto

		cDigBarra := Modu11(cBarra)								//DAC codigo de barras

		cBarra := SubStr(cBarra,1,4) + cDigBarra + SubStr(cBarra,5,39)

		// Composicao da linha digitavel  1 PARTE DE 1
		cParte1 := cBanco 		 				     			//Codigo do banco na camara de compensacao
		cParte1 += cMoeda										//Cod. Moeda
		cParte1 += "1"											//Fixo "9" conforme manual Santander
		cParte1 += SubStr(cAgencia,1,4)							//4 primeiro digitos no numero da agencia (Posição 1 a 4)

		cDig1 := SubStr(cParte1,1,9)                  			//Pega variavel sem o '.'

		cParte1 += Modu10(cDig1)				  	    		//Digito verificador do campo

		// Composicao da linha digitavel 1 PARTE DE 2
		cParte2 := StrZero(Val(alltrim(cCart)),2)        		//Modalidade
		cParte2 += StrZero(Val(_cConvenio),7)					//codigo do cliente
		cParte2 += SubStr(cNroDoc,1,1)							//nosso numero

		cDig2 := SubStr(cParte2,1,10)							//Pega variavel sem o '.'

		cParte2 += Modu10(cDig2)					    		//Digito verificador do campo

		// Composicao da linha digitavel 2 PARTE DE 1
		cParte3 := Substr(cNroDoc,2,6)+cDigNosso				//Nosso Numero+digito
		cParte3 += IIF(Empty(SE1->E1_PARCELA),"001",(StrZero(Val(SE1->E1_PARCELA),3))) //numero da parcela

		cDig3 := SubStr(cParte3,1,10) 			        		//Pega variavel sem o '.'

		cParte3 += Modu10(cDig3)				     			//Digito verificador do campo

		// Composicao da linha digitavel 4 PARTE
		cParte4 := SubStr(cBarra,5,1)							//Digito Verificador do Código de Barras

		// composicao da linha digitavel 5 PARTE
		cParte5 := Fator()										//Fator de vencimento
		cParte5 += StrZero(nValor*100,10)						//Valor do titulo (Saldo no E1)

		cDigital :=  SubStr(cParte1,1,5)+"."+SubStr(cparte1,6,5)+" "+;
			SubStr(cParte2,1,5)+"."+SubStr(cparte2,6,6)+" "+;
			SubStr(cParte3,1,5)+"."+SubStr(cparte3,6,6)+" "+;
			cParte4+" "+cParte5

		AAdd(aRet,cBarra)
		AAdd(aRet,cDigital)
		AAdd(aRet,cNosso)
	EndIf

Return aRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CALC_di9
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function CALC_di9(cVariavel)

	Local Auxi := 0, sumdig := 0

	cbase  := cVariavel
	lbase  := Len(cBase)
	base   := 9
	sumdig := 0
	Auxi   := 0
	iDig   := lBase

	While iDig >= 1

		If base == 1
			base := 9
		EndIf

		auxi   := Val(SubStr(cBase, idig, 1)) * base
		sumdig := SumDig+auxi
		base   := base - 1
		iDig   := iDig-1
	EndDo

	auxi := mod(Sumdig,11)

	If auxi == 10
		auxi := "X"
	Else
		auxi := str(auxi,1,0)
	EndIf

Return(auxi)

//-------------------------------------------------------------------
/*/{Protheus.doc} Modulo11
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
//Static Function Modulo11(cData)
//
//	Local L, D, P := 0
//
//	L := Len(cdata)
//	D := 0
//	P := 1
//
//	While L > 0

//		P := P + 1
//		D := D + (Val(SubStr(cData, L, 1)) * P)

//		If P = 9
//			P := 1
//		End

//		L := L - 1
//	End
//
//	If (D == 0 .Or. D == 1 .Or. D == 10 .Or. D == 11)
//		D := 1
//	End
//
//Return(D)

//-------------------------------------------------------------------
/*/{Protheus.doc} Dig11BB
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function Dig11BB(cData)

	Local Auxi := 0, sumdig := 0

	cbase  := cData
	lbase  := Len(cBase)
	base   := 9	//7
	sumdig := 0
	Auxi   := 0
	iDig   := lBase

	While iDig >= 1

		If base == 1
			base := 9
		EndIf

		auxi   := Val(SubStr(cBase, idig, 1)) * base
		sumdig := SumDig+auxi
		base   := base - 1
		iDig   := iDig-1
	EndDo

	auxi := mod(Sumdig,11)

	If auxi == 10
		auxi := "X"
	Else
		auxi := str(auxi,1,0)
	EndIf

Return(auxi)

//-------------------------------------------------------------------
/*/{Protheus.doc} DigitoBB
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
//Static Function DigitoBB(cData)
//
//	Local Auxi := 0, sumdig := 0
//	cbase  := cData
//	lbase  := Len(cBase)
//	base   := 9
//	sumdig := 0
//	Auxi   := 0
//	iDig   := lBase
//
//	While iDig >= 1
//
//		If base == 1
//			base := 9
//		EndIf
//
//		auxi   := Val(SubStr(cBase, idig, 1)) * base
//		sumdig := SumDig+auxi
//		base   := base - 1
//		iDig   := iDig-1
//	EndDo
//
//	auxi := mod(Sumdig,11)
//
//	If auxi == 10
//		auxi := "X"
//	Else
//		auxi := str(auxi,1,0)
//	EndIf
//
//Return(auxi)

//-------------------------------------------------------------------
/*/{Protheus.doc} DIGIT001
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function DIGIT001(cVariavel)

	Local Auxi := 0, sumdig := 0

	cbase  := cVariavel
	lbase  := Len(cBase)
	umdois := 2
	sumdig := 0
	Auxi   := 0
	iDig   := lBase

	While iDig >= 1
		auxi   	:= Val(SubStr(cBase, idig, 1)) * umdois
		sumdig 	:= SumDig+If (auxi < 10, auxi, (auxi-9))
		umdois 	:= 3 - umdois
		iDig	:= iDig-1
	EndDo

	cValor:=AllTrim(STR(sumdig,12))

	If sumdig == 9
		nDezena := Val(AllTrim(Str(Val(SubStr(cvalor,1,1))+1,12)))
	Else
		nDezena := Val(AllTrim(Str(Val(SubStr(cvalor,1,1))+1,12))+"0")
	EndIf

	auxi := nDezena - sumdig

	If auxi >= 10
		auxi := 0
	EndIf

Return(str(auxi,1,0))

//-------------------------------------------------------------------
/*/{Protheus.doc} Fator
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static function Fator()

	If Len(AllTrim(SubStr(DToC((cAliasTemp)->E1_VENCREA),7,4) ) ) = 4
		cData := SubStr(DToC((cAliasTemp)->E1_VENCREA),7,4) + SubStr(DToS((cAliasTemp)->E1_VENCREA),4,2) + SubStr(DToS((cAliasTemp)->E1_VENCREA),1,2)
	Else
		cData := "20"+SubStr(DToC((cAliasTemp)->E1_VENCREA),7,2) + SubStr(DToS((cAliasTemp)->E1_VENCREA),4,2) + SubStr(DToS((cAliasTemp)->E1_VENCREA),1,2)
	EndIf

	cFator := Str(1000 + ((cAliasTemp)->E1_VENCREA - SToD("20000703")),4)

Return(cFator)

//-------------------------------------------------------------------
/*/{Protheus.doc} CALC_5p
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function CALC_5p(cVariavel)

	Local Auxi := 0, sumdig := 0

	cbase  := cVariavel
	lbase  := Len(cBase)
	base   := 2
	sumdig := 0
	Auxi   := 0
	iDig   := lBase

	While iDig >= 1

		If base >= 10
			base := 2
		EndIf

		auxi   := Val(SubStr(cBase, idig, 1)) * base
		sumdig := SumDig+auxi
		base   := base + 1
		iDig   := iDig-1
	EndDo

	auxi := mod(sumdig,11)

	If auxi == 0 .or. auxi == 1 .or. auxi >= 10
		auxi := 1
	Else
		auxi := 11 - auxi
	EndIf

Return(Str(auxi,1,0))

//-------------------------------------------------------------------
/*/{Protheus.doc} CdBarra_Itau
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
//Static Function CdBarra_Itau()
//
//	Local cDigCdBarra
//	Local cFatVencto	:= ""
//	Local cValor
//	Local nValor
//	Local cCampo1		:= ""
//	Local cCampo2		:= ""
//	Local cCampo3		:= ""
//	Local cCampo4		:= ""
//	Local cCampo5		:= ""
//
//	cFatVencto := StrZero(FatVencto(SEE->EE_CODIGO),4)
//	nValor := Valliq()
//	cValor := StrZero(nValor * 100, 10)
//
//// Calculo do codigo de barras
//	cCdBarra := SEE->EE_CODIGO + "9" + cFatVencto + cValor + cCartEmp + Substr(cNossoNum, 5, 8) + Substr(cNossoNum, 14, 1) +;
//		cAgeEmp + cCtaEmp + cDigEmp + "000"
//
//	cDigCdBarra := Modu11(cCdBarra,9)
//
//	cCdBarra := SEE->EE_CODIGO + "9" + cDigCdBarra + StrZero(FatVencto(SEE->EE_CODIGO), 4) + StrZero(Int(nValor * 100), 10) + cCartEmp + ;
//		Substr(cNossoNum, 5, 8) + Substr(cNossoNum, 14, 1) + cAgeEmp + cCtaEmp + cDigEmp + "000"
//
//// Calculo da representacao numerica
//	cCampo1 := "341" + "9" + cCartEmp + Substr(cNossoNum, 5, 2)
//	cCampo2 := Substr(cNossoNum, 7, 6) + Substr(cNossoNum, 14, 1) + Substr(cAgeEmp, 1, 3)
//	cCampo3 := Substr(cAgeEmp, 4, 1) + cCtaEmp + cDigEmp + "000"
//	cCampo4 := Substr(cCdBarra, 5, 1)
//	cCampo5 := cFatVencto + cValor
//
//// Calculando os DACs dos campos 1, 2 e 3
//	cCampo1 := cCampo1 + Modu10(cCampo1)
//	cCampo2 := cCampo2 + Modu10(cCampo2)
//	cCampo3 := cCampo3 + Modu10(cCampo3)
//
//	cRepNum := Substr(cCampo1, 1, 5) + "." + Substr(cCampo1, 6, 5) + "  "
//	cRepNum += Substr(cCampo2, 1, 5) + "." + Substr(cCampo2, 6, 6) + "  "
//	cRepNum += Substr(cCampo3, 1, 5) + "." + Substr(cCampo3, 6, 6) + "  "
//	cRepNum += cCampo4 + "  "
//	cRepNum += cCampo5
//
//Return

//-------------------------------------------------------------------
/*/{Protheus.doc} AJUSTASX1
Ajusta dicionário SX1 - Perguntas de Usuários
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function AJUSTASX1(cPerg)

	U_uPutSx1(cPerg,"01","De Prefixo"      ,"De Prefixo"      ,"De Prefixo"      ,"mv_ch1","C",03,0,0,"G","","","","","MV_PAR01","","","",""        ,"","","","","","","","","","","","")
	U_uPutSx1(cPerg,"02","Ate Prefixo"     ,"Ate Prefixo"     ,"Ate Prefixo"     ,"mv_ch2","C",03,0,0,"G","","","","","MV_PAR02","","","","ZZZ"     ,"","","","","","","","","","","","")
	U_uPutSx1(cPerg,"03","De Numero"       ,"De Numero"       ,"De Numero"       ,"mv_ch3","C",09,0,0,"G","","","","","MV_PAR03","","","",""        ,"","","","","","","","","","","","")
	U_uPutSx1(cPerg,"04","Ate Numero"      ,"Ate Numero"      ,"Ate Numero"      ,"mv_ch4","C",09,0,0,"G","","","","","MV_PAR04","","","","ZZZZZZ"  ,"","","","","","","","","","","","")
	U_uPutSx1(cPerg,"05","De Parcela"      ,"De Parcela"      ,"De Parcela"      ,"mv_ch5","C",03,0,0,"G","","","","","MV_PAR05","","","",""        ,"","","","","","","","","","","","")
	U_uPutSx1(cPerg,"06","Ate Parcela"     ,"Ate Parcela"     ,"Ate Parcela"     ,"mv_ch6","C",03,0,0,"G","","","","","MV_PAR06","","","","Z"       ,"","","","","","","","","","","","")
	U_uPutSx1(cPerg,"07","De Portador"     ,"De Portador"     ,"De Portador"     ,"mv_ch7","C",03,0,0,"G","","SA6","","","MV_PAR07","","","","001"     ,"","","","","","","","","","","","")
	U_uPutSx1(cPerg,"08","Ate Portador"    ,"Ate Portador"    ,"Ate Portador"    ,"mv_ch8","C",03,0,0,"G","","SA6","","","MV_PAR08","","","","001"     ,"","","","","","","","","","","","")
	U_uPutSx1(cPerg,"09","De Cliente"      ,"De Cliente"      ,"De Cliente"      ,"mv_ch9","C",06,0,0,"G","","SA1","","","MV_PAR09","","","",""        ,"","","","","","","","","","","","")
	U_uPutSx1(cPerg,"10","Ate Cliente"     ,"Ate Cliente"     ,"Ate Cliente"     ,"mv_cha","C",06,0,0,"G","","SA1","","","MV_PAR10","","","","ZZZZZZ"  ,"","","","","","","","","","","","")
	U_uPutSx1(cPerg,"11","De Loja"         ,"De Loja"         ,"De Loja"         ,"mv_chb","C",02,0,0,"G","","","","","MV_PAR11","","","",""        ,"","","","","","","","","","","","")
	U_uPutSx1(cPerg,"12","Ate Loja"        ,"Ate Loja"        ,"Ate Loja"        ,"mv_chc","C",02,0,0,"G","","","","","MV_PAR12","","","","ZZ"      ,"","","","","","","","","","","","")
	U_uPutSx1(cPerg,"13","De Emissao"      ,"De Emissao"      ,"De Emissao"      ,"mv_chd","D",08,0,0,"G","","","","","MV_PAR13","","","","01/01/01","","","","","","","","","","","","")
	U_uPutSx1(cPerg,"14","Ate Emissao"     ,"Ate Emissao"     ,"Ate Emissao"     ,"mv_che","D",08,0,0,"G","","","","","MV_PAR14","","","","31/12/10","","","","","","","","","","","","")
	U_uPutSx1(cPerg,"15","De Vencimento"   ,"De Vencimento"   ,"De Vencimento"   ,"mv_chf","D",08,0,0,"G","","","","","MV_PAR15","","","","01/01/01","","","","","","","","","","","","")
	U_uPutSx1(cPerg,"16","Ate Vencimento"  ,"Ate Vencimento"  ,"Ate Vencimento"  ,"mv_chg","D",08,0,0,"G","","","","","MV_PAR16","","","","31/12/10","","","","","","","","","","","","")
	U_uPutSx1(cPerg,"17","Do Bordero"      ,"Do Bordero"      ,"Do Bordero"      ,"mv_chh","C",06,0,0,"G","","","","","MV_PAR17","","","",""        ,"","","","","","","","","","","","")
	U_uPutSx1(cPerg,"18","Ate Bordero"     ,"Ate Bordero"     ,"Ate Bordero"     ,"mv_chi","C",06,0,0,"G","","","","","MV_PAR18","","","","ZZZZZZ"  ,"","","","","","","","","","","","")
	U_uPutSx1(cPerg,"19","Da Carga"        ,"Da Carga"        ,"Da Carga"        ,"mv_chj","C",06,0,0,"G","","DAK","","","MV_PAR19","","","",""        ,"","","","","","","","","","","","")
	U_uPutSx1(cPerg,"20","Ate Carga"       ,"Ate Carga"       ,"Ate Carga"       ,"mv_chl","C",06,0,0,"G","","DAK","","","MV_PAR20",""   ,""   ,"","ZZZZZZ"  ,"","","","","","","","","","")
	U_uPutSx1(cPerg,"21","Mensagem 1"      ,"Mensagem 1"      ,"Mensagem 1"      ,"mv_chm","C",50,0,0,"G","","","","","MV_PAR21","","","",""        ,"","","","","","","","","","","","")
	U_uPutSx1(cPerg,"22","Mensagem 2"      ,"Mensagem 2"      ,"Mensagem 2"      ,"mv_chn","C",50,0,0,"G","","","","","MV_PAR22","","","",""        ,"","","","","","","","","","","","")

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} Modu10
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function Modu10(cLinha)

	Local nSoma:= 0
	Local nResto
	Local nCont
	Local cDigRet
	Local nResult
	Local lDobra:= .f.
	Local cValor
	Local nAux

	For nCont:= Len(cLinha) To 1 Step -1

		lDobra:= !lDobra

		If lDobra
			cValor:= AllTrim(Str(Val(Substr(cLinha, nCont, 1)) * 2))
		Else
			cValor:= AllTrim(Str(Val(Substr(cLinha, nCont, 1))))
		EndIf

		For nAux:= 1 To Len(cValor)
			nSoma += Val(Substr(cValor, nAux, 1))
		Next nAux
	Next nCont

	nResto:= MOD(nSoma, 10)
	nResult:= 10 - nResto

	If nResult == 10
		cDigRet:= "0"
	Else
		cDigRet:= StrZero(10 - nResto, 1)
	EndIf

Return cDigRet

//-------------------------------------------------------------------
/*/{Protheus.doc} Modu11
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function Modu11(cLinha,cBase,cTipo)

	Local cDigRet
	Local nSoma:= 0
	Local nResto
	Local nCont
	Local nFator:= 9
	Local nResult
	Local _cBase := If( cBase = Nil , 9 , cBase )
	Local _cTipo := If( cTipo = Nil , '' , cTipo )

	For nCont:= Len(cLinha) TO 1 Step -1

		nFator++

		If nFator > _cBase
			nFator:= 2
		EndIf

		nSoma += Val(Substr(cLinha, nCont, 1)) * nFator
	Next nCont

	nResto:= Mod(nSoma, 11)
	nResult:= 11 - nResto

	If SEE->EE_CODIGO == "237" .And. nResult == 10
		cDigRet := "P"
	Else

		If _cTipo = 'P' // Bradesco

			If nResto == 0
				cDigRet:= "0"

			ElseIf  nResto == 1
				cDigRet:= "P"

			Else
				cDigRet:= StrZero(11 - nResto, 1)
			EndIf
		Else

			If nResult == 0 .Or. nResult == 1 .Or. nResult == 10 .Or. nResult == 11
				cDigRet:= "1"
			Else
				cDigRet:= StrZero(11 - nResto, 1)
			EndIf
		EndIf
	EndIf

Return cDigRet

//-------------------------------------------------------------------
/*/{Protheus.doc} NrBordero
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function NrBordero()

	Local _NSEE 	:= 0
	Local lParSEE	:= .F.
	Local nBordero := ""
	Local aBanco 	:= { {"001","B"}, {"237","R"},{"033","S"},{"756","C"},{"341","I"},{"422","A"} }
	Local aBcoRen 	:= { {"001","Z"}, {"237","Y"},{"033","X"},{"756","W"},{"341","V"},{"422","U"} }
	Local lFindSEA := .F.
	Local nPos 	:= 0
	Local nPosRen 	:= 0
	Local lSobBord := SuperGetMV("MV_XSOBBOR",,.T.) //sobrescreve borderô caso ja tenha sido gerado?

	dbSelectArea("SEE")
	SEE->(dbSetOrder(1)) //EE_FILIAL+EE_CODIGO+EE_AGENCIA+EE_CONTA+EE_SUBCTA

	SA1->(dbSetOrder(1))

	If !Empty(SE1->E1_PORTADO) .And. SEE->(dbSeek( xFilial("SEE") + SE1->E1_PORTADO + SE1->E1_AGEDEP + SE1->E1_CONTA))

		While SEE->(!Eof()) .AND. SEE->(EE_FILIAL+EE_CODIGO+EE_AGENCIA+EE_CONTA) == xFilial("SEE") + SE1->E1_PORTADO + SE1->E1_AGEDEP + SE1->E1_CONTA
			if SEE->EE_SUBCTA == "001"
				_nSEE := SEE->(recno())
				EXIT
			endif

			SEE->(DbSkip())
		enddo

	ElseIf SA1->(dbSeek( xFilial("SA1") + (cAliasTemp)->E1_CLIENTE + (cAliasTemp)->E1_LOJA )) .And. !Empty(SA1->A1_BCO1)

		If SEE->(dbSeek( xFilial("SEE") + SA1->A1_BCO1 ))
			_nSEE := SEE->(recno())
		EndIf

	endif

	if _nSEE == 0
		cEOL := CHR(10)
		AVISO("Atenção", "O Cliente Código: "+(cAliasTemp)->E1_CLIENTE+" Loja: "+(cAliasTemp)->E1_LOJA+" não possui banco vinculado ao seu cadastro!";
			+cEOL+"Será impresso o boleto conforme configuração da Rotina 'Configuração Boleto'"  , {"Ok"})

		_nSEE := SuperGetMv("MV_XSEE",,0)
		if empty(_nSEE)
			If !IsBlind()
				Aviso("ATENÇÃO","Configure o parametro MV_XSEE na filial logada!",{"OK"})
			Else
				//conout("O banco "+SEE->EE_CODIGO+" não esta configurado para Impressão Boleto Laser")
			EndIf
			Return .F.
		else
			SEE->(DbGoTo(_nSEE))
			lParSEE := .T.
		endif
	EndIf

	nPos 	:= AScan (aBanco, {|x| x[1] == SEE->EE_CODIGO})
	nPosRen	:= AScan (aBcoRen, {|x| x[1] == SEE->EE_CODIGO})

	If nPos == 0 .or. _nSEE == 0 .OR. SEE->EE_FILIAL <> xFilial("SEE")
		If !IsBlind()
			Aviso("ATENÇÃO","O banco "+SEE->EE_CODIGO+" não esta configurado para Impressão Boleto Laser",{"OK"})
		Else
			//conout("O banco "+SEE->EE_CODIGO+" não esta configurado para Impressão Boleto Laser")
		EndIf
		Return .F.
	EndIf

	// Posiciona nos Parâmetros de Bancos
	If SEE->EE_SUBCTA <> '001'
		If !IsBlind()
			Alert("Erro na leitura dos parametros do banco do bordero gerado (Sub-conta diferente de 001),")
		Else
			//conout("Erro na leitura dos parametros do banco do bordero gerado (Sub-conta diferente de 001)")
		EndIf
		Return .F.
	EndIf

	If !(SEE->EE_CODIGO $ '422/341') .AND. Empty(SEE->EE_CODEMP)
		If !IsBlind()
			Alert("Informar o convenio do banco no cadastro de parametros do banco (EE_CODEMP) !")
		Else
			//conout("Informar o convenio do banco no cadastro de parametros do banco (EE_CODEMP) !")
		EndIf
		Return .F.
	EndIf

	If Empty(SEE->EE_TABELA)
		If !IsBlind()
			Alert("Informar a tabela do banco no cadastro de parametros do banco (EE_TABELA) !")
		Else
			//conout("Informar a tabela do banco no cadastro de parametros do banco (EE_TABELA) !")
		EndIf
		Return .F.
	EndIf

// X - Codigo Banco
// XX - Ano Bordero
// X - Codigo Mes
// XX - Dias

	If SE1->E1_PREFIXO <> "REN" //Renegociação
		nBordero := aBanco[nPos,2] + StrZero( day( dDataBase ),2 ) + Upper(chr( 64+Month( dDataBase ) ) ) + Right( Str( Year( date() ),4 ), 2 )
	Else
		nBordero := aBcoRen[nPos,2] + StrZero( day( dDataBase ),2 ) + Upper(chr( 64+Month( dDataBase ) ) ) + Right( Str( Year( date() ),4 ), 2 )
	EndIf

//Posiciona na Agencia/Conta e Configuracoes bancarias
	SEE->(DbGoTo(_nSEE))
	SA6->(DbSeek( xFilial("SA6")+SEE->EE_CODIGO+SEE->EE_AGENCIA+SEE->EE_CONTA))

	if empty(SE1->E1_NUMBOR) .OR. lSobBord

		RecLock("SE1")
		If AllTrim(FunName()) <> "TRETE017" .Or. lParSEE
			SE1->E1_PORTADO	:= SEE->EE_CODIGO
			SE1->E1_AGEDEP	:= SEE->EE_AGENCIA
			SE1->E1_CONTA	:= SEE->EE_CONTA
		EndIf

		SE1->E1_SITUACA	:= '1'
		SE1->E1_OCORREN	:= '01'
		SE1->E1_NUMBOR	:= nBordero
		SE1->E1_DATABOR	:= dDataBase

		SE1->(MsUnlock())
		SE1->(DbCommit())

		// Coloca o titulo no bordero
		SEA->(DbSetOrder(1))
		lFindSEA := SEA->(DbSeek(xFilial("SEA")+SE1->E1_NUMBOR+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA,.F. ))

		RecLock("SEA",!lFindSEA)

		If !lFindSEA
			SEA->EA_FILIAL  := xFilial( "SEA" )
			SEA->EA_PREFIXO := SE1->E1_PREFIXO
			SEA->EA_NUM     := SE1->E1_NUM
			SEA->EA_PARCELA := SE1->E1_PARCELA
			SEA->EA_FILORIG := cFilAnt
		EndIf

		SEA->EA_NUMBOR  := SE1->E1_NUMBOR
		SEA->EA_TIPO    := SE1->E1_TIPO
		SEA->EA_CART    := "R"
		SEA->EA_PORTADO := SE1->E1_PORTADO
		SEA->EA_AGEDEP  := SE1->E1_AGEDEP
		SEA->EA_DATABOR := SE1->E1_DATABOR
		SEA->EA_NUMCON  := SE1->E1_CONTA
		SEA->EA_SITUACA := SE1->E1_SITUACA
		SEA->EA_TRANSF  := 'S'
		SEA->EA_SITUANT := '0'

		SEA->(MsUnLock())
		SEA->(DbCommit())

		lFindSEA := .T.

	else

		//Localizo o Bordero
		SEA->(DbSetOrder(1))
		lFindSEA := SEA->(DbSeek(xFilial("SEA")+SE1->E1_NUMBOR+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA,.F. ))

		if !lFindSEA
			If !IsBlind()
				Alert("Campo Numero Borderô(E1_NUMBOR) do titulo preenchido mas não encontradao registro do borderô (tabela SEA)!")
			Else
				//conout("Campo Numero Borderô(E1_NUMBOR) do titulo preenchido mas não encontradao registro do borderô (tabela SEA)!")
			EndIf
		endif
		
	endif

Return lFindSEA

//-------------------------------------------------------------------
/*/{Protheus.doc} BradMod11
Nosso numero do banco Bradesco
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function BradMod11(NumBoleta)

	Local Modulo   := 11
	Local strmult  := "2765432765432"
	Local BaseDac  := M->NumBoleta  // Carteira + N Nro
	Local VarDac   := 0, idac := 0

// Calculo do numero bancario + digito e valor do juros
	For idac := 1 To 13
		VarDac := VarDac + Val(Subs(BaseDac, idac, 1)) * Val (Subs (strmult, idac, 1))
	Next idac

	VarDac  := Modulo - VarDac % Modulo
	VarDac  := IIf (VarDac == 10, "P", IIf (VarDac == 11, "0", Str (VarDac, 1)))

Return VarDac

////-------------------------------------------------------------------
///*/{Protheus.doc} DigBarSiCoob
//description
//@author  author
//@since   date
//@version version
///*/
////-------------------------------------------------------------------
//Static Function DigBarSiCoob(CodigoBarra)
//
//	//Local Indice := '43290876543298765432987654329876543298765432'
//	Local somax := 0, contador := 0, digito := 0
//
//	For contador:=1 to 44
//
//		If contador <> 5
//			somax += ( val( Substr(CodigoBarra,contador,1) ) * Val( Substr(CodigoBarra,contador,1) ) )
//			digito := 11 - Mod(SomaX,11)
//		EndIf
//
//		If (digito <= 1) .or. (digito > 9)
//			digito := 1
//		EndIf
//
//	Next contador
//
//Return digito

////-------------------------------------------------------------------
///*/{Protheus.doc} ValidaCodigoBarra
//Valida código de barras
//@author  author
//@since   date
//@version version
///*/
////-------------------------------------------------------------------
//Static Function ValidaCodigoBarra(codigobarra)
//
//	Local Indice := '43290876543298765432987654329876543298765432'
//	Local somax := 0, contador := 0, digito := 0
//
//	For contador := 1 to 44
//
//		If contador <> 5
//			somax += Val( Substr(codigobarra,contador,1) ) * Val( Substr(indice,contador,1) )
//			digito := 11 - Mod(SomaX,11)
//		EndIf
//
//		If (digito <= 1) .or. (digito > 9)
//			digito := 1
//		EndIf
//	Next contador
//
//Return digito

////-------------------------------------------------------------------
///*/{Protheus.doc} Multiplo10
//Calculo do segundo dígito
//@author  author
//@since   date
//@version version
///*/
////-------------------------------------------------------------------
//Static Function Multiplo10(numero)
//
//	Local result := 0
//
//	While Mod(numero,10) <> 0
//		numero += 1
//		result := numero
//	EndDo
//
//Return result

////-------------------------------------------------------------------
///*/{Protheus.doc} SiCoobMod11
//description
//@author  author
//@since   date
//@version version
///*/
////-------------------------------------------------------------------
//Static Function SiCoobMod11(NumBoleta)
//
//	Local Modulo   := 11
//	Local strmult  := "319731973197319731973"
//	Local BaseDac  := M->NumBoleta  // Carteira + N Nro
//	Local VarDac   := 0, idac := 0
//
//// Calculo do numero bancario + digito e valor do juros
//	For idac := 1 To len(NumBoleta)
//		VarDac += Val(Subs(BaseDac, idac, 1)) * Val (Subs (strmult, idac, 1))
//	Next idac
//
//	VarDac  := Modulo - VarDac % Modulo
//	VarDac  := IIf (VarDac < 2 .or. VarDac >= 10, "0", Str(VarDac) )
//
//Return VarDac

//-------------------------------------------------------------------
/*/{Protheus.doc} DigNNSicoob
Nosso Numero banco SICOOB
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function DigNNSicoob(cNNum,cCodEmp,cCodCoop,cParcela)

	Local cCoop   		:= cCodCoop
	Local cClie   		:= StrZero(Val(cCodEmp),10)
	Local nMod    		:= 11
	Local nSoma   		:= 0
	Local nI

	Default cNNum 		:= '0000001'
	Default cParcela	:= '001'

	aCons := {3,1,9,7,3,1,9,7,3,1,9,7,3,1,9,7,3,1,9,7,3,3}

	cSeq := cCoop+cClie+cNNum

	For nI := 1 to Len(cSeq)
		nSoma += Val(SubStr(cSeq,nI,1))*aCons[nI]
	Next

	nDigit := (nSoma % nMod)

	If nDigit <= 1
		cDigit := '0'
	Else
		cDigit := AllTrim(Str(nMod - nDigit))
	EndIf

Return cDigit

////-------------------------------------------------------------------
///*/{Protheus.doc} DigitoLinhaDigitavel
//Calculo da linha digitável
//@author  author
//@since   date
//@version version
///*/
////-------------------------------------------------------------------
//Static Function DigitoLinhaDigitavel(linhadigitavel)
//
//	Local Indice := '2121212120121212121201212121212'
//	Local digito :=0, soma:=0, mult:=0, contador:=0
//	Local codigobarra := ""
//	Local nResult := ""
//
//// Cálculo do primeiro dígito
//	soma := 0
//
//	For contador := 10 to 1 Step -1
//
//		mult := Val( Substr(linhadigitavel,contador,1) ) * Val( Substr(indice,contador,1) )
//
//		If mult >= 10
//			nResult := StrZero(mult,2)
//			soma += Val( Left(nResult,1) ) + Val( Right(nResult,2) )
//		Else
//			soma += mult
//		EndIf
//	Next contador
//
//	digito := multiplo10(soma) - soma
//
//// Coloca o primeiro digito na linha digitável
//	linhadigitavel := Left(linhadigitavel,09,1) + Str(digito,1) + Substr(linhadigitavel,11,40)
//
//// Cálculo do segundo dígito
//	soma := 0
//
//	For contador := 11 To 20
//
//		mult := Val( Substr(linhadigitavel,contador,1) ) * Val( Substr(indice,contador,1) )
//
//		If mult >= 10
//			nResult := StrZero(mult,2)
//			soma += Val( Left(nResult,1) ) + Val( Right(nResult,2) )
//		Else
//			soma += mult
//		EndIf
//	Next contador
//
//	digito := multiplo10(soma) - soma
//
//// Coloca o segundo digito na linha digitável
//	linhadigitavel := Left( linhadigitavel,20) + Str(digito,1) + Substr(linhadigitavel,22,40)
//
//// Cálculo do terceiro dígito
//	soma := 0
//
//	For contador := 22 To 31
//
//		mult := Val(Substr(linhadigitavel,contador,1)) * Val( Substr(indice,contador,1))
//
//		If mult >= 10
//			nResult := StrZero(mult,2)
//			soma += Val( Left(nResult,1) ) + Val( Right(nResult,2) )
//		Else
//			soma += mult
//		EndIf
//	Next contador
//
//// Coloca o terceiro digito na linha digitável
//	linhadigitavel := Left( linhadigitavel,1,31) + Str(digito,1) + Substr(linhadigitavel,33,40)
//
//// Monta o codigo de barra para verificar o último dígito
//	codigobarra := SubStr(linhadigitavel, 01, 03) //Código do Banco
//	codigobarra += SubStr(linhadigitavel, 04, 01) //Moeda
//	codigobarra += SubStr(linhadigitavel, 33, 01) //Digito Verificador
//	codigobarra += SubStr(linhadigitavel, 34, 04) //fator de vencimento
//	codigobarra += SubStr(linhadigitavel, 38, 10) //valor do documento
//	codigobarra += SubStr(linhadigitavel, 05, 01) //Carteira
//	codigobarra += SubStr(linhadigitavel, 06, 04) //Agencia
//	codigobarra += SubStr(linhadigitavel, 11, 02) //Modalidade Cobranca
//	codigobarra += SubStr(linhadigitavel, 13, 07) //Código do Cliente
//	codigobarra += SubStr(linhadigitavel, 20, 01) + SubStr(linhadigitavel, 22, 7)//Nosso Numero
//	codigobarra += SubStr(linhadigitavel, 29, 03) //Parcela
//
//	codigobarra := DigitoCodigoBarra(codigobarra);
//
////Coloca o primeiro digito na linha digitável
//	linhadigitavel := Left(linhadigitavel,32) + Substr(codigobarra,5,1) + Substr(linhadigitavel,32)
//
//Return {linhadigitavel,codigobarra}

//-------------------------------------------------------------------
/*/{Protheus.doc} Dig11Safra
Nosso Numero banco Safra
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function Dig11Safra(cData)

	Local Auxi := 0, sumdig := 0
	Local iDig

	cbase  := cData
	lbase  := Len(cBase)
	base   := 2
	sumdig := 0
	Auxi   := 0
	iDig   := lBase

	For iDig := Len(cBase) To 1 Step -1

		If base == 9
			base := 2
		EndIf

		auxi   := Val(SubStr(cBase, iDig, 1)) * base
		sumdig := SumDig+auxi
		base   += 1
	Next iDig

	auxi := mod(Sumdig,11)

	If auxi == 0
		auxi := "1"
	ElseIf auxi == 1
		auxi := "0"
	Else
		auxi := Str(11-auxi,1,0)
	EndIf

Return(auxi)

//-------------------------------------------------------------------
/*/{Protheus.doc} Dig11Santander
Nosso Numero banco Santander
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function Dig11Santander(cData)

	Local Auxi := 0, sumdig := 0
	Local iDig

	cbase  := cData
	lbase  := Len(cBase)
	base   := 2
	sumdig := 0
	Auxi   := 0
	iDig   := lBase

	For iDig := Len(cBase) To 1 Step -1

		If base == 9
			base := 2
		EndIf

		auxi   := Val(SubStr(cBase, iDig, 1)) * base
		sumdig := SumDig+auxi
		base   += 1
	Next iDig

	auxi := mod(Sumdig,11)

	If auxi == 10
		auxi := "1"
	ElseIf auxi == 1 .Or. auxi == 0
		auxi := "0"
	Else
		auxi := Str(11-auxi,1,0)
	EndIf

Return(auxi)

//-------------------------------------------------------------------
/*/{Protheus.doc} DestMail
Envio Boleto por e-mail
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function DestMail(cCodCli,cLojaCli)

	Local oButton2
	Local oGet1
	Local cGet1 := Space(250)
	Local oGroup1
	Local oSay2
	Local oSay3
	Static oDlg

	Local cMail	:= ""
	Local cMail2:= ""

	DbSelectArea("SA1")
	SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA

	If SA1->(DbSeek(xFilial("SA1")+cCodCli+cLojaCli))
		cMail := AllTrim( SA1->A1_EMAIL )
		cMail += ";" + AllTrim( SA1->A1_XEMAIL )
	Else
		MsgStop("Cadastro do cliente não foi localizado!", "Atencao")
		Return cMail
	EndIf

	If !Empty(cMail2)
		cMail += ";"+cMail2
	EndIf

	cGet1 := cMail

	DEFINE MSDIALOG oDlg TITLE "Boleto por E-Mail" FROM 000, 000  TO 250, 500 COLORS 0, 16777215 PIXEL

	@ 001, 001 GROUP oGroup1 TO 030, 249 PROMPT "Boleto por E-Mail" OF oDlg COLOR 0, 16777215 PIXEL
	@ 008, 005 SAY oSay3 PROMPT "Confirme o endereço de e-mail que será enviado o boleto. Os endereços devem ser separados por ponto e vírgula ( ; )." SIZE 237, 019 OF oDlg COLORS 0, 16777215 PIXEL
	@ 051, 007 SAY oSay2 PROMPT "Para:" SIZE 015, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 047, 020 GET oGet1 VAR cGet1 OF oDlg MULTILINE SIZE 223, 044 COLORS 0, 16777215 HSCROLL PIXEL
	@ 094, 166 BUTTON oButton2 PROMPT "Enviar" SIZE 071, 025 OF oDlg PIXEL ACTION ( IIF(Empty(AllTrim(cGet1)),MsgStop("Informe pelo menos um endereço de e-mail!","Atencao"),(AddEmail(cGet1),oDlg:End())) )

	ACTIVATE MSDIALOG oDlg CENTERED

Return cGet1

//-------------------------------------------------------------------
/*/{Protheus.doc} AddEmail
Joga os emails digitados pelo usuario em um array aEmails
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function AddEmail(cEmail)

	Local aEmails := {}
	Local _nPos := 0
	Local i

// Joga os emails digitados pelo usuario em um array aEmails
	While Len(AllTrim(cEmail)) > 0

		_nPos := At(";",cEmail)-1

		If _nPos > 0
			aAdd(aEmails,SubStr(cEmail,1,_nPos))
		Else
			If Len(AllTrim(cEmail)) > 0
				aAdd(aEmails,AllTrim(cEmail))
			Else
				aAdd(aEmails,"")
			EndIf
		EndIf

		If _nPos <= 0
			cEmail := ""
		Else
			cEmail := SubStr(cEmail,_nPos+2)
		EndIf
	EndDo

// Caso algum email digitado não esteja no cadastro do cliente, dou a opção de incluí-lo.
	For i := 1 To Len(aEmails)

		If !(aEmails[i] $ SA1->A1_EMAIL)

			If !(aEmails[i] $ SA1->A1_XEMAIL)

				If MSGYESNO("O e-mail <"+aEmails[i]+"> não está cadastro para o cliente "+;
						AllTrim(SA1->A1_COD)+" - "+AllTrim(SA1->A1_LOJA)+" - "+AllTrim(SA1->A1_NOME)+CRLF+;
						"Deseja incluir no cadastro do cliente ?","Atenção")

					If RecLock("SA1",.F.)
						SA1->A1_XEMAIL := IIF(Empty(AllTrim(SA1->A1_XEMAIL)),aEmails[i],AllTrim(SA1->A1_XEMAIL)+";"+aEmails[i])
						SA1->(MsUnlock())
					Else
						MsgInfo("Não foi possivel incluir o e-mail.","Atencao")
					EndIf
				EndIf
			EndIf
		EndIf
	Next i

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} ExcRelPd
Excluir arquivos .rel e ._pd
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function ExcRelPd(cFilePrint,cDirBol,cDirBolRel)

//Apaga .rel e .pd_, se houverem
//.pd_
	If File("spool\" + cFilePrint + ".pd_")
		//conout("Arquivo " + "spool\" + cFilePrint + ".pd_" + " localizado.")
		If FErase("spool\" + cFilePrint + ".pd_") == 0
			//conout("Arquivo " + "spool\" + cFilePrint + ".pd_" + " apagado.")
		EndIf
	EndIf
	If File(SuperGetMv("MV_XDIRBOL",,GetTempPath()) + cFilePrint + ".pd_")
		//conout("Arquivo " + SuperGetMv("MV_XDIRBOL",,GetTempPath()) + cFilePrint + ".pd_" + " localizado.")
		If FErase(SuperGetMv("MV_XDIRBOL",,GetTempPath()) + cFilePrint + ".pd_") == 0
			//conout("Arquivo " + SuperGetMv("MV_XDIRBOL",,GetTempPath()) + cFilePrint + ".pd_" + " apagado.")
		EndIf
	EndIf
	If File("C:\TOTVS\Protheus11\Data\Protheus_Data_Ofc\system\" + cDirBol + cFilePrint + ".pd_")
		//conout("Arquivo " + "C:\TOTVS\Protheus11\Data\Protheus_Data_Ofc\system\" + cDirBol + cFilePrint + ".pd_" + " localizado.")
		If FErase("C:\TOTVS\Protheus11\Data\Protheus_Data_Ofc\system\" + cDirBol + cFilePrint + ".pd_") == 0
			//conout("Arquivo " + "C:\TOTVS\Protheus11\Data\Protheus_Data_Ofc\system\" + cDirBol + cFilePrint + ".pd_" + " apagado.")
		EndIf
	EndIf
	If File("C:\TOTVS 12\Microsiga\data\data_oficial\system\" + cDirBol + cFilePrint + ".pd_")
		//conout("Arquivo " + "C:\TOTVS 12\Microsiga\data\data_oficial\system\" + cDirBol + cFilePrint + ".pd_" + " localizado.")
		If FErase("C:\TOTVS 12\Microsiga\data\data_oficial\system\" + cDirBol + cFilePrint+".pd_") == 0
			//conout("Arquivo " + "C:\TOTVS 12\Microsiga\data\data_oficial\system\" + cDirBol + cFilePrint + ".pd_" + " apagado.")
		EndIf
	EndIf
	If File(cDirBolRel + cFilePrint + ".pd_")
		//conout(cDirBolRel + cFilePrint + ".pd_" + " localizado.")
		If FErase(cDirBolRel + cFilePrint+".pd_") == 0
			//conout(cDirBolRel + cFilePrint + ".pd_" + " apagado.")
		EndIf
	EndIf

//.rel
	If File("spool\" + cFilePrint + ".rel")
		//conout("Arquivo " + "spool\" + cFilePrint + ".rel" + " localizado.")
		If FErase("spool\" + cFilePrint + ".rel") == 0
			//conout("Arquivo " + "spool\" + cFilePrint + ".rel" + " apagado.")
		EndIf
	EndIf
	If File(SuperGetMv("MV_XDIRBOL",,GetTempPath()) + cFilePrint + ".rel")
		//conout("Arquivo " + SuperGetMv("MV_XDIRBOL",,GetTempPath()) + cFilePrint + ".rel" + " localizado.")
		If FErase(SuperGetMv("MV_XDIRBOL",,GetTempPath()) + cFilePrint + ".rel") == 0
			//conout("Arquivo " + SuperGetMv("MV_XDIRBOL",,GetTempPath()) + cFilePrint + ".rel" + " apagado.")
		EndIf
	EndIf
	If File("C:\TOTVS\Protheus11\Data\Protheus_Data_Ofc\system\" + cDirBol + cFilePrint + ".rel")
		//conout("Arquivo " + "C:\TOTVS\Protheus11\Data\Protheus_Data_Ofc\system\" + cDirBol + cFilePrint + ".rel" + " localizado.")
		If FErase("C:\TOTVS\Protheus11\Data\Protheus_Data_Ofc\system\" + cDirBol + cFilePrint + ".rel") == 0
			//conout("Arquivo " + "C:\TOTVS\Protheus11\Data\Protheus_Data_Ofc\system\" + cDirBol + cFilePrint + ".rel" + " apagado.")
		EndIf
	EndIf
	If File("C:\TOTVS 12\Microsiga\data\data_oficial\system\" + cDirBol + cFilePrint + ".rel")
		//conout("Arquivo " + "C:\TOTVS 12\Microsiga\data\data_oficial\system\" + cDirBol + cFilePrint + ".rel" + " localizado.")
		If FErase("C:\TOTVS 12\Microsiga\data\data_oficial\system\" + cDirBol + cFilePrint+".rel") == 0
			//conout("Arquivo " + "C:\TOTVS 12\Microsiga\data\data_oficial\system\" + cDirBol + cFilePrint + ".rel" + " apagado.")
		EndIf
	EndIf
	If File(cDirBolRel + cFilePrint + ".rel")
		//conout(cDirBolRel + cFilePrint + ".rel" + " localizado.")
		If FErase(cDirBolRel + cFilePrint+".rel") == 0
			//conout(cDirBolRel + cFilePrint + ".rel" + " apagado.")
		EndIf
	EndIf

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} RetQtdRen
Quantidade de parcelas de um título
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function RetQtdRen(cCli,cLojaCli,cPref,cNum,cTipo)

	Local nQtd 	:= 1
	Local cQry	:= ""

	If Select("QRYREN") > 0
		QRYREN->(dbCloseArea())
	EndIf

	cQry := "SELECT COUNT(E1_PARCELA) AS QTDREN"
	cQry += " FROM "+RetSqlName("SE1")+""
	cQry += " WHERE D_E_L_E_T_ <> '*'"
	cQry += " AND E1_CLIENTE	= '"+cCli+"'"
	cQry += " AND E1_LOJA		= '"+cLojaCli+"'"
	cQry += " AND E1_PREFIXO	= '"+cPref+"'"
	cQry += " AND E1_NUM		= '"+cNum+"'"
	cQry += " AND E1_TIPO		= '"+cTipo+"'"

	cQry := ChangeQuery(cQry)
	TcQuery cQry NEW Alias "QRYREN"

	If QRYREN->(!EOF())
		nQtd := QRYREN->QTDREN
	EndIf

	If Select("QRYREN") > 0
		QRYREN->(dbCloseArea())
	EndIf

Return nQtd



/*/{Protheus.doc} User Function TRETR09A
Selecao de Carteira
@type  Function
@author user
@since 03/02/2022
@version version
/*/
User Function TRETR09A()

//Criar parametro MV_XSEE sem ele não funciona

Local oBTCancela
Local oBTOk
Local oFont09Arial := TFont():New("Arial",,017,,.T.,,,,,.F.,.F.)
Local oFont10Arial := TFont():New("Arial Narrow",,018,,.T.,,,,,.F.,.F.)
Local oGroup1
Local oGroup2
Local oGroup3
Local oSay1
Local oSay2
Local oSay3
Local oSay4
Local oSay5
Local oSay6
Local oSay7

Private oCarteira
Private oContaCorrente
Private oNossoNumero
Private oNrConvenio
Private oAgencia
Private oBanco
Private oOperacao
Private oSubCta


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Preparo o ambiente na qual sera executada a rotina de negocio      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
//PREPARE ENVIRONMENT EMPRESA "01" FILIAL "01" TABLES "SB1","SB2","SB5","SA6","SEE"

Private cAgencia := ""
Private cCarteira := ""
Private cBanco := ""
Private cContaCorrente := ""
Private cNossoNumero := ""
Private cNrConvenio := ""
Private cSubCta := space( Len(SEE->EE_SUBCTA) )
Private _nRecno	:= 0 	// Nova Variavel para Tratamento do Recno na Hora de Gravar
Private _aPreencher := {}
Private cOperacao := 1
Private _nxOperacao := 0	// Recno 

Static oDlg

  DEFINE MSDIALOG oDlg TITLE " Seleção Carteira Ativa " FROM 000, 000  TO 290, 500 COLORS 0, 16777215 PIXEL

    @ 004, 007 SAY oSay2 PROMPT "Informe abaixo as informações de Banco/Agencia/Conta e carteira cadastrada na rotina (Parametros Bancarios):" SIZE 232, 020 OF oDlg FONT oFont10Arial COLORS 0, 16777215 PIXEL
    @ 063, 010 SAY oSay1 PROMPT "Banco:" SIZE 022, 007 OF oDlg FONT oFont09Arial COLORS 0, 16777215 PIXEL
    @ 080, 072 SAY oSay3 PROMPT "Conta:" SIZE 024, 007 OF oDlg FONT oFont09Arial COLORS 0, 16777215 PIXEL
    @ 081, 010 SAY oSay4 PROMPT "Agência:" SIZE 028, 007 OF oDlg FONT oFont09Arial COLORS 0, 16777215 PIXEL
    @ 081, 147 SAY oSay5 PROMPT "Carteira:" SIZE 029, 007 OF oDlg FONT oFont09Arial COLORS 0, 16777215 PIXEL
	@ 097, 010 SAY oSay6 PROMPT "Nr. Convênio:" SIZE 048, 007 OF oDlg FONT oFont09Arial COLORS 0, 16777215 PIXEL
	@ 097, 104 SAY oSay7 PROMPT "Nosso Número Atual:" SIZE 050, 008 OF oDlg FONT oFont09Arial COLORS 0, 16777215 PIXEL

    @ 062, 039 MSGET oBanco VAR cBanco SIZE 185, 010 OF oDlg COLORS 0, 16777215 READONLY PIXEL
    @ 079, 098 MSGET oContaCorrente VAR cContaCorrente SIZE 044, 010 OF oDlg COLORS 0, 16777215 READONLY PIXEL
    @ 079, 039 MSGET oAgencia VAR cAgencia SIZE 026, 010 OF oDlg COLORS 0, 16777215 READONLY PIXEL
    @ 079, 177 MSGET oCarteira VAR cCarteira SIZE 014, 010 OF oDlg COLORS 0, 16777215 READONLY PIXEL    
    @ 095, 059 MSGET oNrConvenio VAR cNrConvenio SIZE 036, 010 OF oDlg COLORS 0, 16777215 READONLY PIXEL    
    @ 095, 158 MSGET oNossoNumero VAR cNossoNumero SIZE 065, 010 OF oDlg COLORS 0, 16777215 READONLY PIXEL

	_aPreencher	:= xPreencher()		// Deve ser criado
	
	@ 042, 009 MSCOMBOBOX oOperacao VAR cOperacao ITEMS _aPreencher SIZE 228, 010 OF oDlg COLORS 0, 16777215 ON CHANGE ( xAtuCmp() ) PIXEL

	_nRecno := xLeMV() 			// Deve ser Criado

	xAtuCmp()

    @ 055, 004 GROUP oGroup1 TO 116, 244 OF oDlg COLOR 0, 16777215 PIXEL
    @ 032, 004 GROUP oGroup2 TO 058, 244 PROMPT " Parametro de Configuração (Ativo)  " OF oDlg COLOR 0, 16777215 PIXEL
    @ 023, 006 GROUP oGroup3 TO 027, 244 OF oDlg COLOR 0, 16777215 PIXEL
    
    DEFINE SBUTTON oBTCancela 	FROM 132, 190 TYPE 02 OF oDlg ONSTOP "Cancela Operação" 		ENABLE ACTION oDlg:End()
    DEFINE SBUTTON oBTOk 		FROM 132, 218 TYPE 01 OF oDlg ONSTOP "Confirma as alterações" 	ENABLE ACTION {|| xAtuMV(), oDlg:End() }
    
	ACTIVATE MSDIALOG oDlg CENTERED

Return


// 
// Atualiza parametro com o Recno
//
Static Function xAtuMV()

//	_nPos := aScan(_aPreencher,{|x| StrZero(_nRecno,4) $ x} )
	//PutMv("MV_XSEE",_nRecno)
	PutMvPar("MV_XSEE",_nRecno)
Return


//
// Preenche vetor da combobox
// 
Static Procedure xPreencher()
	Local _aRegistros := {}
                
	cEOL := CHR(10)
	SEE->(dbsetorder(1))  //Criado pelo Athos Data 11/10/2013
	SEE->(dbseek(xFilial("SEE")))
	SEE->(DbGoTop())
	while !SEE->(EOF())
		if SEE->EE_FILIAL == xFilial("SEE") 
			aadd(_aRegistros, StrZero(SEE->(RecNo()),4)+" / "+AllTrim(SEE->EE_OPER)+" AG:"+AllTrim(SEE->EE_AGENCIA)+" C/C:"+AllTrim(SEE->EE_CONTA)+" CART:"+SEE->EE_CODCART+" / SUB CTA: "+ SEE->EE_SUBCTA )	
		endif
		SEE->(dbskip())
	enddo
	//SEE->( DbEval( {|| aadd(_aRegistros, StrZero(RecNo(),4)+" / "+AllTrim(SEE->EE_OPER)+" AG:"+AllTrim(SEE->EE_AGENCIA)+" C/C:"+AllTrim(SEE->EE_CONTA)+" CART:"+SEE->EE_CODCART )   } ) )
    
    if len(_aRegistros) == 0
    	aadd(_aRegistros, "000"+" / "+"000"+" AG:"+"000"+" C/C:"+"000"+" CART:"+"000" )	
    	AVISO("Atenção", "Não existe nenhum parãmetro de banco cadastrado (Tabela SEE)!"+cEOL+ "Favor faça o cadastramento conforme Banco/Boleto."  , {"Ok"})	    	
    endif
    
Return _aRegistros


//
// Le o parametros Gravados
//
Static Function xLeMV()
Local _nPos := 0
     
	_nRecno := SuperGetMv ( "MV_XSEE", .F., SEE->( Recno() ) )
	SEE->( DbGoTo( _nRecno ) )

	_nPos := aScan(_aPreencher,{|x| StrZero(_nRecno,4) $ x} )

	if _nPos > 0
		oOperacao:Nat := _nPos
		oOperacao:Select(_nPos)
	else
		oOperacao:Nat := 1
	endif

	oOperacao:Refresh()
Return _nRecno


// 
// Atualiza Campos da oDlg
//
Static Function xAtuCmp()

_nRecno := Val( Left(_aPreencher[oOperacao:Nat],4) )
SEE->( DbGoTo( _nRecno ) )

M->cAgencia			:= SEE->EE_AGENCIA
M->cCarteira		:= SEE->EE_CODCART
M->cBanco			:= SEE->EE_CODIGO
M->cContaCorrente 	:= SEE->EE_CONTA
M->cNossoNumero		:= SEE->EE_FAXATU
M->cNrConvenio		:= SEE->EE_CODEMP
M->cOperacao		:= SEE->EE_CODIGO + " - " + AllTrim(SEE->EE_OPER)

oCarteira:Refresh()
oContaCorrente:Refresh()
oNossoNumero:Refresh()
oNrConvenio:Refresh()
oAgencia:Refresh()
oBanco:Refresh()
oOperacao:Refresh()

oDlg:Refresh()

Return .T.
