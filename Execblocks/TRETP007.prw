#include "PROTHEUS.CH"
#include "TOPCONN.CH"

/*/{Protheus.doc} TRETP007
Chamado pelo P.E MT103FIM para tratamento do complemento na CD6 - posto
@author Ricardo Quintais
@since 04/11/14
@version 1.0
@return Nulo

@type function
/*/

User Function TRETP007()

local _cfor      	:= _cDoc:=_cCrc:=_cSerie:=''
Local _nopc      	:= Paramixb[1]
Local _nConfirma 	:= PARAMIXB[2]
Local _aArea     	:= GetArea()
Local aAreaSD1		:= SD1->(GetArea())
Local nPosPedido	:= aScan(aHeader,{|x| AllTrim(x[2]) == "D1_PEDIDO"})
Local nPosCRC		:= aScan(aHeader,{|x| AllTrim(x[2]) == "D1_XCRC"})
Local lComb			:= .F.
Local cMvCombus		:= SuperGetMV("MV_COMBUS",,"")
Local cMvEstado		:= SuperGetMv("MV_ESTADO",,"")
Local cMvTransp 	:= SuperGetMv("ESP_TRANSP",.f.,"000001") //ZE3->ZE3_TRANSP
Local cMvVeicul  	:= superGetMv("ESP_VEICUL",.f.,"1491") //ZE3->ZE3_VEICUL
Local cMvMotori		:= SuperGetMv("ESP_MOTOR",.f.,"986981")  //ZE3->ZE3_MOTORI

//Local _cNF		:= SF1->F1_DOC  	// numero do documento - G.SAMPAIO - 27/07/2016
//Local _cSer		:= SF1->F1_SERIE	// serie do documento  - G.SAMPAIO - 27/07/2016
//Local _cForn		:= SF1->F1_FORNECE	// fornecedor  - G.SAMPAIO - 27/07/2016
//Local _cLj		:= SF1->F1_LOJA		// loja do fornecedor  - G.SAMPAIO - 27/07/2016
//Local _cTime		:= Time()			// hora de inc. - G.SAMPAIO - 27/07/2016
Local nX

Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
//Caso o Posto Inteligente não esteja habilitado não faz nada...
If !lMvPosto
	Return
EndIf

If (_nOpc==3.or._nOpc==4).and._nConfirma==1//Quintais

	DbSelectArea("SD1")
	SD1->(DbSetOrder(1)) //D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM

	If SD1->(DbSeek(xFilial("SD1")+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA))

		While SD1->(!EOF()) .And. xFilial("SF1") == SD1->D1_FILIAL .And. SF1->F1_DOC == SD1->D1_DOC .And. SF1->F1_SERIE == SD1->D1_SERIE .And.;
				SF1->F1_FORNECE == SD1->D1_FORNECE .And. SF1->F1_LOJA == SD1->D1_LOJA

			If SD1->D1_GRUPO $ cMvCombus
				//MHZ_FILIAL+MHZ_CODPRO+MHZ_LOCAL
				if !empty(Posicione("MHZ",3,xFilial("MHZ")+SD1->D1_COD,"MHZ_CODTAN"))
					lComb := .T.
					Exit
				endif
			Endif

			SD1->(DbSkip())
		EndDo
	Endif

	RestArea(aAreaSD1)

	If select("MT103F")>0
		MT103F->(DbCloseArea())
	Endif

	cQry:="SELECT D1_FILIAL,D1_DOC,D1_SERIE,D1_LOCAL,D1_FORNECE,D1_LOJA,D1_ITEM,D1_COD,D1_QUANT,D1_XCRC FROM " + RetSqlname("SD1") +" SD1"
	cQry+=" INNER JOIN " +RetSqlName("ZE4") +" ZE4 ON(ZE4_FILIAL=D1_FILIAL AND ZE4_PEDIDO=D1_PEDIDO  AND ZE4.D_E_L_E_T_<>'*')"//AND D1_ITEMPC=ZE4_ITEMPE
	cQry+=" WHERE SD1.D_E_L_E_T_<>'*' AND D1_FILIAL='"+SF1->F1_FILIAL+"' AND D1_DOC='"+SF1->F1_DOC+"' AND D1_SERIE='"+SF1->F1_SERIE+"' AND D1_TIPO<>'D'"
	cQry+=" AND D1_FORNECE='"+SF1->F1_FORNECE+"' AND D1_LOJA='"+SF1->F1_LOJA+"' AND D1_GRUPO IN ("+U_URetIn(GetMV("MV_COMBUS"))+")"  //SO PEGA ITENS DE COMBUSTIVEL
	cQry+=" GROUP BY D1_FILIAL,D1_DOC,D1_SERIE,D1_LOCAL,D1_FORNECE,D1_LOJA,D1_ITEM,D1_COD,D1_QUANT,D1_XCRC"
	cQry := ChangeQuery(cQry)

	TcQuery cQry New Alias "MT103F"

	If MT103F->(!Eof())

		While MT103F->(!Eof())

			_cDoc:=MT103F->D1_DOC
			_cFor:=MT103F->D1_FORNECE
			_cCrc:=MT103F->D1_XCRC
			_cSerie:=MT103F->D1_SERIE

			//-- Consultar tabela de código ANP
			cProdANP := IIF(SB1->(FieldPos("B1_CODSIMP"))>0,Posicione("SB1",1,xFilial("SB1")+(MT103F->D1_COD),"B1_CODSIMP"),"")
			cProdANP := IIF(!Empty(cProdANP),cProdANP,Posicione("SB5",1,xFilial("SB5")+(MT103F->D1_COD),"B5_CODANP")) //B5_FILIAL+B5_COD

			Reclock("CD6",.T.)
			CD6->CD6_FILIAL	:= xFilial("CD6")
			CD6->CD6_TPMOV	:= "E"
			CD6->CD6_SERIE	:= MT103F->D1_SERIE
			CD6->CD6_DOC	:= MT103F->D1_DOC
			CD6->CD6_CLIFOR	:= MT103F->D1_FORNECE
			CD6->CD6_LOJA	:= MT103F->D1_LOJA
			CD6->CD6_ITEM	:= MT103F->D1_ITEM //StrZero(_nSeq,4)//MT103F->D1_ITEM
			CD6->CD6_COD	:= MT103F->D1_COD
			CD6->CD6_CODANP	:= cProdANP
			if CD6->(FieldPos("CD6_DESANP")) > 0 //-- Descrição do produto-ANP (Utilizado na geração da tag <descANP>)
				CD6->CD6_DESANP := Posicione("SZO",1,xFilial("SZO")+cProdANP,"ZO_DESCRI") //ZO_FILIAL+ZO_CODCOMB
			endif
			CD6->CD6_UFCONS	:= cMvEstado
			CD6->CD6_ESPEC	:= SF1->F1_ESPECIE
			CD6->CD6_TRANSP	:= ''  //VALIDAR TRANSPORTADORA
			CD6->CD6_HORA	:= IIF(Empty(SF1->F1_HORA),Time(),SF1->F1_HORA)
			CD6->CD6_VOLUME	:= MT103F->D1_QUANT //VALIDAR VOLUME

			//TABELA ZE3 - CABECALHO DO CRC
			DbSelectArea("ZE3")
			ZE3->(DbSetOrder(1)) //ZE3_FILIAL+ZE3_NUMERO
			DbSeek(xFilial("ZE3")+AllTrim(MT103F->D1_XCRC))

			CD6->CD6_TRANSP := ZE3->ZE3_TRANSP
			CD6->CD6_PLACA  := ZE3->ZE3_VEICUL
			CD6->CD6_MOTOR  := ZE3->ZE3_MOTORI
			CD6->CD6_CPFMOT := Posicione("DA4",1,xFilial("DA4")+ZE3->ZE3_MOTORI,"DA4_CGC")

			cQry:="SELECT * FROM " + RetSqlName("ZE4")
			cQry+=" WHERE D_E_L_E_T_<>'*' AND ZE4_FILIAL='"+SF1->F1_FILIAL+"'"
			cQry+=" AND ZE4_NUMERO='"+_cCrc+"' AND ZE4_PRODUT='"+MT103F->D1_COD+"'"
			cQry+=" AND ZE4_QTDE='"+Str(MT103F->D1_QUANT)+"'"
			cQry := ChangeQuery(cQry)
			TcQuery cQry New Alias "MT103FA"

			//CD6->CD6_TANQUE := Posicione("ZE0",1,xFilial("ZE0")+MT103F->ZE4_TANQUE,"ZE0_GRPTQ")
			CD6->CD6_TANQUE := Posicione("ZE0",1,xFilial("ZE0")+MT103FA->ZE4_TQ,"ZE0_GRPTQ")

			CD6->CD6_QTDE   := MT103FA->ZE4_QTDE
			CD6->CD6_UFPLAC := Posicione("DA3",1,xFilial("DA3")+ZE3->ZE3_VEICUL,"DA3_ESTPLA")
			CD6->CD6_SEFAZ  := Iif(Empty(SF1->F1_CHVNFE),"0",SF1->F1_CHVNFE)
			//CD6->CD6_VOLUME :=Iif(Empty(SF1->F1_VOLUME),1,)
			CD6->CD6_PBRUTO :=Iif(Empty(SF1->F1_PBRUTO),1,SF1->F1_PBRUTO)
			CD6->CD6_PLIQUI :=Iif(Empty(SF1->F1_PLIQUI),1,SF1->F1_PLIQUI)
			CD6->CD6_QTAMB  := MT103F->D1_QUANT
			//Tratamento da cide deve ser customizado
			CD6->CD6_BCCIDE :=0 //BASE DA CIDE (IMPOSTO)
			CD6->CD6_VCIDE  :=0

			//MHZ_FILIAL+MHZ_CODPRO+MHZ_LOCAL
			if CD6->(ColumnPos("CD6_PBIO")) > 0
				if !empty(Posicione("MHZ",3,xFilial("MHZ")+MT103F->D1_COD+MT103F->D1_LOCAL,"MHZ_CODTAN"))
					CD6->CD6_INDIMP := MHZ->MHZ_INDIMP
					CD6->CD6_UFORIG := MHZ->MHZ_UFORIG
					CD6->CD6_PORIG  := MHZ->MHZ_PORIG
					CD6->CD6_PBIO 	:= MHZ->MHZ_PBIO
				endif
			endif

			Msunlock()

			MT103FA->(DbCloseArea())

			MT103F->(DbSkip())

		Enddo

		MT103F->(DbCloseArea())

		//Atualizando os dados da amostra com o numero da nota fiscal
		cQry:="UPDATE "  + RetSqlName("ZE5")
		cQry+=" SET ZE5_DOC = '" + _cDoc + "', "
		cQry+=" ZE5_SERIE = '" + _cSerie + "' , "
		cQry+=" ZE5_FORNEC = '" + _cFor + "' "
		cQry+=" WHERE D_E_L_E_T_<> '*' "
		cQry+=" AND ZE5_FILIAL = '" + xFilial("ZE5") + "' "
		cQry+=" AND ZE5_CRC = '" + _cCrc + "'"
		TcSqlExec(cQry)

		//Atualizando os dados do CRC
		cQry:="UPDATE "  + RetSqlName("ZE3")
		cQry+=" SET ZE3_NOTA = '" + _cDoc + "', "
		cQry+=" ZE3_SERIE = '" + _cSerie + "' , "
		cQry+=" ZE3_USUENC = '" + RetCodUsr() + "' , "
		cQry+=" ZE3_HRFIM = '" + SubStr(Time(),1,5) + "' , "
		cQry+=" ZE3_DATA = '" + DTOS(dDataBase) + "' "
		cQry+=" WHERE D_E_L_E_T_ <> '*' "
		cQry+=" AND ZE3_FILIAL = '" + xFilial("ZE3") + "' "
		cQry+=" AND ZE3_NUMERO = '" + _cCrc + "' "
		TcSqlExec(cQry)

	ElseIf AllTrim(SF1->F1_TIPO)=='D' // Quintais (Tratamento para devolução de combustivel) - neste caso nao tem CRC de entrada

		If Select("MT103FD")>0
			MT103FD->(DbCloseARea())
		Endif

		cQry:="SELECT D1_FILIAL,D1_DOC,D1_LOCAL,D1_SERIE,D1_FORNECE,D1_LOJA,D1_ITEM,D1_COD,D1_QUANT FROM " + RetSqlname("SD1") +" SD1"
		cQry+=" WHERE SD1.D_E_L_E_T_<>'*' AND D1_FILIAL='"+SF1->F1_FILIAL+"' AND D1_DOC='"+SF1->F1_DOC+"' AND D1_SERIE='"+SF1->F1_SERIE+"' AND D1_TIPO='D'" //DEVOLUCAO DEVE ALIMENTAR CD6
		cQry+=" AND D1_FORNECE='"+SF1->F1_FORNECE+"' AND D1_LOJA='"+SF1->F1_LOJA+"' AND D1_GRUPO IN ("+U_URetIn(GetMV("MV_COMBUS"))+")"  //SO PEGA PARA ITENS DE COMBUSTIVEL
		cQry+=" GROUP BY D1_FILIAL,D1_DOC,D1_LOCAL,D1_SERIE,D1_FORNECE,D1_LOJA,D1_ITEM,D1_COD,D1_QUANT"
		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "MT103FD"

		cMsgCD6 := ""
		While MT103FD->(!Eof())

			//cProdANP := Posicione("SB5",1,xFilial("SB5")+AllTrim(MT103FD->D1_COD),"B5_CODANP") //B5_FILIAL+B5_COD
			//-- Consultar tabela de código ANP
			cProdANP := IIF(SB1->(FieldPos("B1_CODSIMP"))>0,Posicione("SB1",1,xFilial("SB1")+(MT103FD->D1_COD),"B1_CODSIMP"),"")
			cProdANP := IIF(!Empty(cProdANP),cProdANP,Posicione("SB5",1,xFilial("SB5")+(MT103FD->D1_COD),"B5_CODANP")) //B5_FILIAL+B5_COD

			Reclock("CD6",.T.)
			CD6->CD6_FILIAL	:= xFilial("CD6")
			CD6->CD6_TPMOV	:= "E"
			CD6->CD6_SERIE	:= MT103FD->D1_SERIE
			CD6->CD6_DOC	:= MT103FD->D1_DOC
			CD6->CD6_CLIFOR	:= MT103FD->D1_FORNECE
			CD6->CD6_LOJA	:= MT103FD->D1_LOJA
			CD6->CD6_ITEM	:= MT103FD->D1_ITEM //StrZero(_nSeq,4)//MT103F->D1_ITEM
			CD6->CD6_COD	:= MT103FD->D1_COD
			CD6->CD6_CODANP	:= cProdANP
			if CD6->(FieldPos("CD6_DESANP")) > 0 //-- Descrição do produto-ANP (Utilizado na geração da tag <descANP>)
				CD6->CD6_DESANP := Posicione("SZO",1,xFilial("SZO")+cProdANP,"ZO_DESCRI") //ZO_FILIAL+ZO_CODCOMB
			endif
			CD6->CD6_UFCONS	:= cMvEstado
			CD6->CD6_ESPEC	:= SF1->F1_ESPECIE
			CD6->CD6_TRANSP	:= ''  //VALIDAR TRANSPORTADORA
			CD6->CD6_HORA	:= IIF(Empty(SF1->F1_HORA),Time(),SF1->F1_HORA)
			CD6->CD6_VOLUME	:= MT103FD->D1_QUANT //VALIDAR VOLUME

			CD6->CD6_TRANSP := cMvTransp //SuperGetMv("ESP_TRANSP",.f.,"000001") //ZE3->ZE3_TRANSP
			CD6->CD6_PLACA  := cMvVeicul //superGetMv("ESP_VEICUL",.f.,"1491") //ZE3->ZE3_VEICUL
			CD6->CD6_MOTOR  := cMvMotori //SuperGetMv("ESP_MOTOR",.f.,"986981")  //ZE3->ZE3_MOTORI
			CD6->CD6_CPFMOT := Posicione("DA4",1,xFilial("DA4")+cMvMotori,"DA4_CGC")

			If  Select("TANQUE")>0
				TANQUE->(DbCloseArea())
			Endif

			cQry:="SELECT ZE0_TANQUE FROM "+ RetSqlName("ZE0")+ " ZE0"
			cQry+=" INNER JOIN "+RetSqlName("MHZ")+" MHZ ON (MHZ.D_E_L_E_T_ = ' ' AND ZE0.ZE0_GRPTQ = MHZ.MHZ_CODTAN AND MHZ.MHZ_LOCAL = '"+MT103FD->D1_LOCAL+"')"
			cQry+=" WHERE ZE0.D_E_L_E_T_ = ' '"
			cQry := ChangeQuery(cQry)
			TcQuery cQry New Alias "TANQUE"

			CD6->CD6_TANQUE := IIF(!Empty(TANQUE->ZE0_TANQUE),TANQUE->ZE0_TANQUE,"000") 
			CD6->CD6_QTDE   := MT103FD->D1_QUANT
			CD6->CD6_UFPLAC := Posicione("DA3",1,xFilial("DA3")+cMvVeicul,"DA3_ESTPLA")
			CD6->CD6_SEFAZ  := Iif(Empty(SF1->F1_CHVNFE),"0",SF1->F1_CHVNFE)
			//CD6->CD6_VOLUME :=Iif(Empty(SF1->F1_VOLUME),1,0)
			CD6->CD6_PBRUTO :=Iif(Empty(SF1->F1_PBRUTO),1,SF1->F1_PBRUTO)
			CD6->CD6_PLIQUI :=Iif(Empty(SF1->F1_PLIQUI),1,SF1->F1_PLIQUI)
			CD6->CD6_QTAMB  := MT103FD->D1_QUANT
			//Tratamento da cide deve ser customizado
			CD6->CD6_BCCIDE :=0 //BASE DA CIDE (IMPOSTO)
			CD6->CD6_VCIDE  :=0

			//MHZ_FILIAL+MHZ_CODPRO+MHZ_LOCAL
			if CD6->(ColumnPos("CD6_PBIO")) > 0
				if !empty(Posicione("MHZ",3,xFilial("MHZ")+MT103FD->D1_COD+MT103FD->D1_LOCAL,"MHZ_CODTAN"))
					CD6->CD6_INDIMP := MHZ->MHZ_INDIMP
					CD6->CD6_UFORIG := MHZ->MHZ_UFORIG
					CD6->CD6_PORIG  := MHZ->MHZ_PORIG
					CD6->CD6_PBIO 	:= MHZ->MHZ_PBIO
				endif
			endif

			Msunlock()

			cMsgCD6 += "Registro CD6 incluído para o documento "+AllTrim(SF1->F1_DOC)+"/"+AllTrim(SF1->F1_SERIE)+", item "+AllTrim(MT103FD->D1_ITEM)+"." + CRLF

			MT103FD->(Dbskip())
		Enddo

		If !IsBlind() .and. !Empty(cMsgCD6)
			//MsgInfo(cMsgCD6,"Atenção")
		Endif

		//MsgInfo("Lançando Complemento de Combustível da NF:"+AllTrim(SF1->F1_DOC)+"/"+AllTrim(SF1->F1_SERIE),"Atenção")
	Endif //Fim da nota fiscal com combustivel (D1_GRUPO $ MV_COMBUS)

	// verifico se o campo F1_XLMC esta criado na base - G.SAMPAIO 10/08/2016
	If SF1->(FieldPos("F1_XLMC" )) > 0

		If lComb .AND. !IsInCallStack("LOJA720")
			If !IsBlind()
				MsgInfo("Documento de Entrada "+AllTrim(SF1->F1_DOC)+"/"+AllTrim(SF1->F1_SERIE)+" irá compor LMC.","Atenção")
			endif

			//Atualiza flag LMC
			RecLock("SF1",.F.)
				SF1->F1_XLMC := "S"
			SF1->(MsUnlock())
		Endif

	EndIf

elseif _nOpc == 5 .and. _nConfirma == 1 // Wellington Gonçalves, excluir o flag do CRC e das amostras quando o documento de entrada for excluído

	// percorro os itens do documento de entrada
	For nX := 1 To Len(aCols)

		// se o número do CRC estiver preenchido
		if !Empty(aCols[nx,nPosCRC])

			// posiciono no CRC para limpar o flag da nota
			ZE3->(DbSetOrder(1)) // ZE3_FILIAL + ZE3_NUMERO
			if ZE3->(DbSeek(xFilial("ZE3") + aCols[nx,nPosCRC]))

				if RecLock("ZE3",.F.)

					ZE3->ZE3_NOTA 	:= ""
					ZE3->ZE3_SERIE 	:= ""
					ZE3->ZE3_USUENC	:= ""
					ZE3->ZE3_HRFIM 	:= ""
					ZE3->ZE3_DATA 	:= CTOD("  /  /    ")
					ZE3->(MsUnLock())

				endif

			endif

			// posiciono na amostra para limpar o flag da nota
			ZE5->(DbSetOrder(1)) // ZE5_FILIAL + ZE5_PEDIDO + ZE5_ITEMPE + ZE5_LACRAM
			if ZE5->(DbSeek(xFilial("ZE5") + aCols[nx,nPosPedido]))

				While ZE5->(!Eof()) .AND. ZE5->ZE5_FILIAL == xFilial("ZE5") .AND. ZE5->ZE5_PEDIDO == aCols[nx,nPosPedido]

					if RecLock("ZE5",.F.)

						ZE5->ZE5_DOC := ""
						ZE5->ZE5_SERIE := ""
						ZE5->ZE5_FORNEC := ""
						ZE5->(MsUnLock())

					endif

					ZE5->(DbSkip())

				EndDo

			endif

		endif

	Next nX

Endif

RestArea(_aArea)
RestArea(aAreaSD1)

Return
