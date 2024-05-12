#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TOTVS.CH'
#INCLUDE 'TOPCONN.CH'
#INCLUDE 'TBICONN.CH'

/*/{Protheus.doc} TRETM022
Ponto de Entrada da Rotina de Cadastro de Regras de Negociação de Clientes.

@author Pablo Cavalante
@since 07/05/2015
@version 1.0
@return Nil
@type function
/*/
User Function TRETM022()

	Local aParam     := PARAMIXB
	Local xRet       := .T.
	Local oObj       := ''
	Local cIdPonto   := ''
	Local cIdModel   := ''
	Local cClasse    := ''
	Local lIsGrid    := .F.
	Local nLinha     := 0
	Local nQtdLinhas := 0
	Local cMsg       := ''

	If aParam <> NIL

		oObj       := aParam[1]
		cIdPonto   := aParam[2]
		cIdModel   := IIf( oObj<> NIL, oObj:GetId(), aParam[3] ) //cIdModel   := aParam[3]
		cClasse    := IIf( oObj<> NIL, oObj:ClassName(), '' )

		lIsGrid    := ( Len( aParam ) > 3 ) .and. cClasse == 'FWFORMGRID'

		If lIsGrid
			nQtdLinhas := oObj:GetQtdLine()
			nLinha     := oObj:nLine
		EndIf

		If cIdPonto == 'MODELVLDACTIVE'

		ElseIf cIdPonto == 'BUTTONBAR'

		ElseIf cIdPonto == 'FORMLINEPRE'

		ElseIf cIdPonto ==  'FORMPRE'

		ElseIf cIdPonto == 'FORMPOS'

		ElseIf cIdPonto == 'FORMLINEPOS'

		ElseIf cIdPonto ==  'MODELPRE'

		ElseIf cIdPonto == 'MODELPOS'

			If oObj:GetOperation() <> 5 // se a operação for inclusão ou alteração
				xRet := ValidaCab(oObj) // função que valida o cabeçalho e chave duplicada
			EndIf

		ElseIf cIdPonto == 'FORMCOMMITTTSPRE'

		ElseIf cIdPonto == 'FORMCOMMITTTSPOS'

		ElseIf cIdPonto == 'MODELCOMMITTTS'

		ElseIf cIdPonto == 'MODELCOMMITNTTS'

			MODELCOMMITNTTS(oObj)

		ElseIf cIdPonto == 'MODELCANCEL'

		EndIf

	EndIf

Return xRet

/*/{Protheus.doc} MODELCOMMITNTTS
Chamada apos a gravação total do modelo e fora da transação (MODELCOMMITNTTS).
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@param oObj, object, descricao
@type function
/*/
Static Function MODELCOMMITNTTS(oObj)

	Local oModelU52	:= oObj:GetModel( 'U52MASTER' )
	Local oModelU53 := oObj:GetModel( 'U53DETAIL' )
	Local aArea     := GetArea()
	Local aAreaU52	:= U52->(GetArea())
	Local aAreaU53	:= U53->(GetArea())
	Local aAreaU25	:= U25->(GetArea())
	Local cCondicao, bCondicao
	Local nX

	Static oSay

	// envio o registro para retaguarda e/ou PDV
	If oObj:GetOperation() == 3 // inclusão
		cOperad := "I"
	ElseIf oObj:GetOperation() == 4 //alteração
		cOperad := "A"
	ElseIf oObj:GetOperation() == 5  //exclusão
		cOperad := "E"
	EndIf

	//U52_FILIAL+U52_CODCLI+U52_LOJA+U52_GRPVEN+U52_CLASSE+U52_SATIV1
	U_UREPLICA("U52", 1, xFilial("U52")+oModelU52:GetValue('U52_CODCLI')+oModelU52:GetValue('U52_LOJA')+oModelU52:GetValue('U52_GRPVEN')+oModelU52:GetValue('U52_CLASSE')+oModelU52:GetValue('U52_SATIV1'), cOperad)

	For nX := 1 To oModelU53:Length()

		// posiciono na linha atual
		oModelU53:Goline(nX)

		If oModelU53:IsDeleted(nX) .OR. cOperad == "E"

			//verificar se existe preço negociado e encerra-los
			cLog := ""
			lOk  := .T.
			FWMsgRun(, {|oSay| lOk := U_TRET023K(@oSay, @cLog, oModelU52:GetValue('U52_CODCLI'), oModelU52:GetValue('U52_LOJA'), oModelU52:GetValue('U52_GRPVEN'), oModelU53:GetValue('U53_FORMPG'), oModelU53:GetValue('U53_CONDPG')) }, "Aguarde! Processando...", "Ajuste dos Preços Negociados..." )

			/*
			if !empty(oModelU52:GetValue('U52_CODCLI')+oModelU52:GetValue('U52_LOJA')) .or. !empty(oModelU52:GetValue('U52_GRPVEN'))

				cCondicao := " U25_FILIAL == '"+xFilial("U25")+"'"
				cCondicao += " .AND. DTOS(U25_DTINIC) <= '"+DTOS(ddatabase)+"'"
				cCondicao += " .AND. ((DTOS(U25_DTFIM) == '"+DTOS(CTOD(""))+"' .AND. Empty(U25->U25_HRFIM)) .OR. (DTOS(U25_DTFIM)+U25->U25_HRFIM >= '"+DTOS(ddatabase)+SUBSTR(Time(),1,5)+"'))" //somente com data de fim dentro da vigencia
				cCondicao += " .AND. Empty(U25_NUMORC)" //para trazer somente preços que nao foram utilizdos em venda específica
				if !empty(oModelU52:GetValue('U52_CODCLI')+oModelU52:GetValue('U52_LOJA'))
					cCondicao += " .AND. U25_CLIENT == '"+oModelU52:GetValue('U52_CODCLI')+"' .AND. U25_LOJA == '"+oModelU52:GetValue('U52_LOJA')+"' "
				elseif !empty(oModelU52:GetValue('U52_GRPVEN'))
					cCondicao += " .AND. U25_GRPCLI == '"+oModelU52:GetValue('U52_GRPVEN')+"' "
				endif
				cCondicao += " .AND. U25_FORPAG == '"+oModelU53:GetValue('U53_FORMPG')+"' .AND. U25_CONDPG == '"+oModelU53:GetValue('U53_CONDPG')+"' "
				cCondicao += " .AND. U25_BLQL <> 'S' "

				// limpo os filtros da U25
				U25->(DbClearFilter())

				// executo o filtro na U25
				bCondicao 	:= "{|| " + cCondicao + " }"
				U25->(DbSetFilter(&bCondicao,cCondicao))

				// vou para a primeira linha
				U25->(DbSetOrder(2)) //U25_FILIAL+U25_PRODUT+U25_CLIENT+U25_LOJA+U25_GRPCLI+U25_FORPAG+U25_CONDPG+U25_ADMFIN+U25_EMITEN+U25_LOJEMI+U25_PLACA+DTOS(U25_DTINIC)+U25_HRINIC
				U25->(DbGoTop())

				while U25->(!Eof())
					//faz encerramento do preço
					StaticCall(UFATA001, EncerrLck, dDataBase, Time() )

					U25->(DbSkip())
				enddo

				U25->(DbClearFilter())
			endif
			*/
			//U53_FILIAL+U53_CODCLI+U53_LOJA+U53_GRPVEN+U53_CLASSE+U53_SATIV1+U53_ITEM
			U_UREPLICA("U53", 1, xFilial("U53")+oModelU52:GetValue('U52_CODCLI')+oModelU52:GetValue('U52_LOJA')+oModelU52:GetValue('U52_GRPVEN')+oModelU52:GetValue('U52_CLASSE')+oModelU52:GetValue('U52_SATIV1')+oModelU53:GetValue('U53_ITEM'), "E")
		Else
			//U53_FILIAL+U53_CODCLI+U53_LOJA+U53_GRPVEN+U53_CLASSE+U53_SATIV1+U53_ITEM
			U_UREPLICA("U53", 1, xFilial("U53")+oModelU52:GetValue('U52_CODCLI')+oModelU52:GetValue('U52_LOJA')+oModelU52:GetValue('U52_GRPVEN')+oModelU52:GetValue('U52_CLASSE')+oModelU52:GetValue('U52_SATIV1')+oModelU53:GetValue('U53_ITEM'), cOperad)
		EndIf

	Next nX

	if cOperad $ "IA"
		if !empty(oModelU52:GetValue('U52_CODCLI')+oModelU52:GetValue('U52_LOJA'))
			if MsgYesNo("Deseja cadastrar preços negociados para este cliente agora?", "Atenção")
				SA1->(DbSetOrder(1))
				SA1->(DbSeek(xFilial("SA1")+oModelU52:GetValue('U52_CODCLI')+oModelU52:GetValue('U52_LOJA')))

				INCLUI := .F. //altero para nao dar problema nos inic padrão

				U_TRETA023(	2/*nOpcX*/,;
				/*lPDV*/,;
				oModelU52:GetValue('U52_CODCLI') /*_cCliente*/,;
				oModelU52:GetValue('U52_LOJA') /*_cLoja*/,;
				/*_cPlaca*/,;
				/*_cAdmFin*/,;
				/*_cEmiCh*/, /*_cLojEmi*/,;
				/*_cFomPg*/,/*cCondPg*/ )
			endif
		endif
	endif

	RestArea( aAreaU25 )
	RestArea( aAreaU52 )
	RestArea( aAreaU53 )
	RestArea( aArea )
Return NIL

/*/{Protheus.doc} ValidaCab
Função que valida os dados do cadastro
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@param oObj, object, descricao
@type function
/*/
Static Function ValidaCab(oObj)

	Local lRet 		:= .T.
	Local oModelU52	:= oObj:GetModel('U52MASTER')
	Local oModelU53	:= oObj:GetModel('U53DETAIL')
	Local cCodCli	:= oModelU52:GetValue('U52_CODCLI')
	Local cGrpCli	:= oModelU52:GetValue('U52_GRPVEN')
	Local cClaCli	:= oModelU52:GetValue('U52_CLASSE')
	Local cAtiCli	:= oModelU52:GetValue('U52_SATIV1')
	Local nItens	:= oModelU53:Length()
	Local nX		:= 0

	If Empty(cCodCli) .and. Empty(cGrpCli) .and. Empty(cClaCli) .and. Empty(cAtiCli)
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Valida Campos do Cabecalho:  	                     ³
		//³Cliente, Grupo de Cliente, Classe, Atividade          ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		Help( ,, 'Help','Cabeçalho!',;
		"Favor preencher os campos obrigatórios - Verifique os campos 'Cliente / Grp de Cliente / Classe / Segmento'" , 1, 0)
		lRet := .F.
	Else

		/*For nX:=1 To nItens

		oModelU53:Goline(nX)
		If (!oModelU53:IsDeleted(nX)) .And. (!Empty(oModelU53:GetValue('U53_PROD')) .or. !Empty(oModelU53:GetValue('U53_GRUPO')))

		//(!Empty(oModelU53:GetValue('U53_PROD')) .And. Empty(oModelU53:GetValue('U53_PRCTAB'))) .Or.;
		If ((oModelU53:GetValue('U53_GERAAC')=='S' .and. (Empty(oModelU53:GetValue('U53_COTCAO')) .or. (Empty(oModelU53:GetValue('U53_QTDPTO')) .and. !Empty(oModelU53:GetValue('U53_PRCTAB')))))) .or.;
		Empty(oModelU53:GetValue('U53_TIPO'))
		Help(,,'Help',,"Não foram informados todos os campos obrigatórios (Tipo Ponto / Cotacao / Qtd Pontos). Verifique o item " + oModelU53:GetValue('U53_ITEM') + ".", 1, 0)
		lRet := .F.
		Exit
		EndIf

		If oModelU53:GetValue('U53_GERAAC') == 'N' //Gera Acerto? S/N
		If oModelU53:GetValue('U53_COTCAO') > 0
		Help(,,'Help',,"Não pode existir cotação para um item que não gera acerto. Verifique o item " + oModelU53:GetValue('U53_ITEM') + ".", 1, 0)
		lRet := .F.
		Exit
		EndIf

		If (oModelU53:GetValue('U53_DESCON') <= 0) .and. (oModelU53:GetValue('U53_PRCTAB') > 0)
		Help(,,'Help',,"Para itens que não gera acerto deverá ser preenchido o valor de desconto. Verifique o item " + oModelU53:GetValue('U53_ITEM') + ".", 1, 0)
		lRet := .F.
		Exit
		EndIf
		EndIf

		EndIf

		Next nX*/

	EndIf

Return(lRet)
