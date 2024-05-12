#INCLUDE "FWMVCDEF.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPRINTSETUP.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "COLORS.CH"
#INCLUDE "FONT.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "PROTHEUS.CH"

#DEFINE DMPAPER_A4 9

/*/{Protheus.doc} TRETR010
Relatório de Impressão de Requisições Pré e Pós
@author thebr
@since 29/04/2019
@version 1.0
@return Nil
@type function
/*/
user function TRETR010(lMail,cU56,cParcela,lJob)

	Local cLocal			:= "C:\spool\"

	Private lAdjustToLegacy	:= .F.
	Private lDisableSetup	:= .T.
	Private	cImag001		:= GetSrvProfString("Startpath","")+"lgrlfat.png"

	Private oCalib9N	:=	TFont():New("Calibri",,9,,.T.,,,,,.F.,.F.)
	Private oCalibr9  	:=	TFont():New("Calibri",,9,,.F.,,,,,.F.,.F.)
	Private oCalibr12N  :=	TFont():New("Calibri",,12,,.T.,,,,,.F.,.F.)
	Private oCalibr12  	:=	TFont():New("Calibri",,12,,.F.,,,,,.F.,.F.)

	Private oPrinter
	Private cFilePrint  := ""
	Private lSetp		:= lMail
	Private cParc		:= iif(!empty(cParcela),cParcela,"")

	Default lJob		:= .T. //nao mostra as mensagens

	DbSelectArea("U56")
	If !Empty(cU56)
		U56->(DbSetOrder(1)) //U56_FILIAL+U56_PREFIX+U56_CODIGO
		U56->(DbSeek(cU56))
	EndIf

	If U56->U56_STATUS <> 'L'
		If !IsBlind() //se nao for rotina automatica
			MsgStop("Requisição ainda não liberada. Favor efetuar o processo de liberação!","Atenção")
		Else
			//Conout("TRETR010: Requisição ainda não liberada. Favor efetuar o processo de liberação!")
		EndIf
		Return()
	EndIf

	If !ExistDir("C:\spool")// verifica se existe o diretorio
		MakeDir("C:\spool")// cria o diretorio
	EndIf

	If !ExistDir("\spool")
		MakeDir("\spool")
	EndIf

	cFilePrint := "REQUISICAO"+ cFilAnt + Str( Year( date() ),4) + StrZero( Month( date() ), 2) +;
	StrZero( Day( date() ),2) + Left(Time(),2) + Substr(Time(),4,2) + Right(Time(),2)

	If !lSetp
		oPrinter := FWMSPrinter():New(cFilePrint, IMP_PDF, lAdjustToLegacy, cLocal, lDisableSetup, , , , , , .F., )
		oPrinter:Setup()

		If oPrinter:nModalResult != PD_OK
			oPrinter := Nil
			Return
		endif
	EndIf

	printPage()

	If oPrinter:nModalResult == PD_OK
		oPrinter:Preview()
	EndIf

return .T.

//
// gera a impressao dos dados da requisição (U56, U57 e U58)
//
Static Function printPage()

	Local aArea 	:= GetArea()
	Local aAreaU56 	:= U56->(GetArea())
	Local aAreaU57  := U57->(GetArea())
	Local nLin		:= 0
	Local nColB1 	:= 0020 //posicao da coluna esquerdo do box
	Local nColB2 	:= 0560 //posicao da coluna direito do box
	Local nColT1 	:= 0030 //posicao da coluna do texto titulo 1
	Local nColC1 	:= 0100 //posicao da coluna do texto conteudo 1
	Local nColT2 	:= 0330 //posicao da coluna do texto titulo 2
	Local nColC2 	:= 0400 //posicao da coluna do texto conteudo 2
	Local oBrush 	:= TBrush():New( , RGB(205,205,205) ) //cinza claro
	Local aObs   	:= {}
	Local nX := nY	:= 0
	Local cLocal	:= "\spool\"
	Local cNomeM0   := SuperGetMv("TP_IREQNM0",,"M0_NOME/M0_NOMECOM") //define campos da SM0 a usar na seção Filiais Autorizadas
	Local aNomeM0	:= StrToKArr(cNomeM0,"/")

	If !isBlind()
		cLocal	:= "C:\spool\"
	endif

	DbSelectArea("U56")
	DbSelectArea("U57")
	U57->(dbsetorder(1)) //U57_FILIAL+U57_PREFIX+U57_CODIGO+U57_PARCEL
	If U57->(dbseek(xFilial("U57")+U56->U56_PREFIX+U56->U56_CODIGO+cParc))// Caso seja passado no parametro a parcela será enviada somente ela.

		While U57->(!Eof()) .and. U57->U57_FILIAL == xFilial("U57") .and. U57->U57_PREFIX == U56->U56_PREFIX .and. U57->U57_CODIGO == U56->U56_CODIGO

			If lSetp
				oPrinter := FWMSPrinter():New(cFilePrint, IMP_PDF, lAdjustToLegacy, cLocal, lDisableSetup)
				oPrinter:SetPortrait()
				oPrinter:SetPaperSize(DMPAPER_A4)
				oPrinter:SetMargin(40,70,40,70)
				oPrinter:lInJob := .T.
			EndIf

			oPrinter:StartPage() //inicia uma nova pagina

			//1° quadrante
			nLin := 0040
			oPrinter:Box(nLin,nColB1,nLin+0070,nColB2)

			oPrinter:Say(nLin+35,nColT1,"Requisição Protheus",oCalibr12N,,0)

			cCode128 := AllTrim(U57->U57_PREFIX + U57->U57_CODIGO + U57->U57_PARCEL) //codigo de barras da requisição == chave do registro
			oPrinter:FWMSBAR("CODE128"/*cTypeBar*/,4.2/*nRow*/,0016/*nCol*/,cCode128/*cCode*/,oPrinter/*oPrint*/,/*lCheck*/,/*Color*/,/*lHorz*/,0.025/*nWidth*/,1.0/*nHeigth*/,.F./*lBanner*/,"Calibri"/*cFont*/,/*cMode*/,.F./*lPrint*/,/*nPFWidth*/,/*nPFHeigth*/,/*lCmtr2Pix*/)
			oPrinter:Say(nLin+60,nColT1+200,cCode128,oCalibr12N,,0)

			oPrinter:SayBitMap(0055,0420,cImag001,0124,0039)

			nLin := nLin+0070

			//2° quadrante
			oPrinter:Box(nLin,nColB1,nLin+0100,nColB2)

			cDescrCx := ""
			If U56->U56_TIPO == '1' /*1=Pre-Paga;2=Pos-Paga*/ .and. U57->U57_TUSO == 'C' /*C=Consumo;S=Saque*/
				cDescrCx := "REQUISIÇÃO PRÉ-PAGA CONSUMO (DEPÓSITO EM CONTA CONSUMO)"
			ElseIf U56->U56_TIPO == '2' /*1=Pre-Paga;2=Pos-Paga*/ .and. U57->U57_TUSO == 'C' /*C=Consumo;S=Saque*/
				cDescrCx := "REQUISIÇÃO PÓS-PAGA CONSUMO"
			ElseIf U56->U56_TIPO == '1' /*1=Pre-Paga;2=Pos-Paga*/ .and. U57->U57_TUSO == 'S' /*C=Consumo;S=Saque*/
				cDescrCx := "REQUISIÇÃO PRÉ-PAGA SAQUE (DEPÓSITO EM CONTA SAQUE)"
			ElseIf U56->U56_TIPO == '2' /*1=Pre-Paga;2=Pos-Paga*/ .and. U57->U57_TUSO == 'S' /*C=Consumo;S=Saque*/
				cDescrCx := "REQUISIÇÃO PÓS-PAGA SAQUE (VALE MOTORISTA)"
			EndIf
			oPrinter:Say(nLin+10,nColT1,cDescrCx,oCalib9N,,0)
			nLin := nLin+0010

			oPrinter:Say(nLin+10,nColT1,"N. Requisição:",oCalib9N,,0)
			oPrinter:Say(nLin+20,nColT1,"Tipo:",oCalib9N,,0)
			oPrinter:Say(nLin+30,nColT1,"Motorista:",oCalib9N,,0)
			oPrinter:Say(nLin+40,nColT1,"Placa:",oCalib9N,,0)
			oPrinter:Say(nLin+50,nColT1,"Cliente:",oCalib9N,,0)
			oPrinter:Say(nLin+60,nColT1,"Telefone:",oCalib9N,,0)
			oPrinter:Say(nLin+70,nColT1,"Requisitante:",oCalib9N,,0)
			oPrinter:Say(nLin+80,nColT1,"Valor Parcela:",oCalib9N,,0)

			oPrinter:Say(nLin+10,nColC1,U56->U56_PREFIX+U56->U56_CODIGO,oCalibr9,,0)
			oPrinter:Say(nLin+20,nColC1,AllTrim(X3Combo("U56_TIPO",U56->U56_TIPO)),oCalibr9,,0)
			cCpfMot := iif(!empty(U57->U57_MOTORI),TransForm(U57->U57_MOTORI,"@R 999.999.999-99")+" - "+Posicione("DA4",3,xFilial("DA4")+U57->U57_MOTORI,"DA4_NOME"),"")
			oPrinter:Say(nLin+30,nColC1,cCpfMot,oCalibr9,,0)
			cPlaca := iif(!empty(U57->U57_PLACA),TransForm(U57->U57_PLACA,"@!R NNN-9N99")+ " - " + RetField('DA3',1,xFilial("DA3")+U57->U57_PLACA,'DA3_DESC'),"")
			oPrinter:Say(nLin+40,nColC1,cPlaca,oCalibr9,,0)
			oPrinter:Say(nLin+50,nColC1,U56->U56_CODCLI+"/"+U56->U56_LOJA+" - "+Posicione("SA1",1,xFilial("SA1")+U56->U56_CODCLI+U56->U56_LOJA,"A1_NOME"),oCalibr9,,0)
			oPrinter:Say(nLin+60,nColC1,Posicione("SA1",1,xFilial("SA1")+U56->U56_CODCLI+U56->U56_LOJA,"A1_TEL"),oCalibr9,,0)
			oPrinter:Say(nLin+70,nColC1,AllTrim(U56->U56_REQUIS),oCalibr9,,0)
			oPrinter:Say(nLin+80,nColC1,"R$ "+AllTrim(TransForm(U57->U57_VALOR,"@E 999,999,999,999.99")),oCalibr9,,0)

			oPrinter:Say(nLin+10,nColT2,"Parcela:",oCalib9N,,0)
			oPrinter:Say(nLin+20,nColT2,"Tipo de Uso:",oCalib9N,,0)
			oPrinter:Say(nLin+30,nColT2,"Celular:",oCalib9N,,0)
			oPrinter:Say(nLin+50,nColT2,"CPF/CNPJ:",oCalib9N,,0)
			oPrinter:Say(nLin+60,nColT2,"E-mail:",oCalib9N,,0)
			oPrinter:Say(nLin+70,nColT2,"Cargo:",oCalib9N,,0)


			oPrinter:Say(nLin+10,nColC2,U57->U57_PARCEL,oCalibr9,,0)
			oPrinter:Say(nLin+20,nColC2,AllTrim(X3Combo("U57_TUSO",U57->U57_TUSO)),oCalibr9,,0)
			oPrinter:Say(nLin+30,nColC2,RetField("DA4",3,xFilial("DA4")+U57->U57_MOTORI,"DA4_TEL"),oCalibr9,,0)
			If Posicione("SA1",1,xFilial("SA1")+U56->U56_CODCLI+U56->U56_LOJA,"A1_PESSOA") == "J"
				oPrinter:Say(nLin+50,nColC2,transform(Posicione("SA1",1,xFilial("SA1")+U56->U56_CODCLI+U56->U56_LOJA,"A1_CGC"),"@R 99.999.999/9999-99"),oCalibr9,,0)
			Else//If SA1->A1_PESSOA == "F"
				oPrinter:Say(nLin+50,nColC2,transform(Posicione("SA1",1,xFilial("SA1")+U56->U56_CODCLI+U56->U56_LOJA,"A1_CGC"),"@R 999.999.999-99"),oCalibr9,,0)
			Endif
			oPrinter:Say(nLin+60,nColC2,Posicione("SA1",1,xFilial("SA1")+U56->U56_CODCLI+U56->U56_LOJA,"A1_EMAIL"),oCalibr9,,0)
			oPrinter:Say(nLin+70,nColC2,AllTrim(U56->U56_CARGO),oCalibr9,,0)

			nLin := nLin+0090

			If !Empty(U56->U56_OBS)

				aObs := QuebraTexto(strtran(U56->U56_OBS, chr(13)+chr(10), " "),110)
				oPrinter:Box(nLin,nColB1,nLin+(0010*(1+len(aObs)+1)),nColB2)

				//fazer laço para quebra de linha
				oPrinter:Say(nLin+10,nColT1,"Observação:",oCalib9N,,0)
				nLin := nLin+0010
				for nX := 1 to len(aObs)
					oPrinter:Say(nLin+10,nColT1,aObs[nX],oCalibr9,,0)
					nLin := nLin+0010
				next nX
				nLin := nLin+0010

			EndIf

			//5° quadrante
			oPrinter:Box(nLin,nColB1,nLin+0010,nColB2)

			oPrinter:FillRect( {nLin+1,nColB1+1,nLin+0010-1,nColB2-1} , oBrush)
			oPrinter:Say(nLin+7,0245,Capital(Alltrim(SM0->M0_NOME)),oCalib9N,,1)

			nLin := nLin+0010

			//6° quadrante
			oPrinter:Box(nLin,nColB1,nLin+0050,nColB2)

			oPrinter:Say(nLin+10,nColT1,"Unidade:",oCalib9N,,0)
			oPrinter:Say(nLin+20,nColT1,"Município:",oCalib9N,,0)
			oPrinter:Say(nLin+30,nColT1,"Telefone:",oCalib9N,,0)
			oPrinter:Say(nLin+40,nColT1,"Emissão:",oCalib9N,,0)

			oPrinter:Say(nLin+10,nColC1,SubStr(AllTrim(SM0->M0_NOME) + " / " + AllTrim(SM0->M0_NOMECOM),1,50),oCalibr9,,0)
			oPrinter:Say(nLin+20,nColC1,AllTrim(SM0->M0_CIDCOB) + " - " + AllTrim(SM0->M0_ESTCOB),oCalibr9,,0)
			oPrinter:Say(nLin+30,nColC1,AllTrim(SM0->M0_TEL),oCalibr9,,0)
			oPrinter:Say(nLin+40,nColC1,DtoC(DDataBase),oCalibr9,,0)

			oPrinter:Say(nLin+10,nColT2,"Filial:",oCalib9N,,0)
			oPrinter:Say(nLin+10,nColC2,SubStr(AllTrim(SM0->M0_FILIAL),1,38),oCalibr9,,0)
			oPrinter:Say(nLin+20,nColT2,"CNPJ:",oCalib9N,,0)
			oPrinter:Say(nLin+20,nColC2,Transform(SM0->M0_CGC,"@R 99.999.999/9999-99"),oCalibr9,,0)

			nLin := nLin+0050

			If !Empty(U56->U56_FILAUT)
				//7° quadrante
				oPrinter:Box(nLin,nColB1,nLin+0010,nColB2)

				oPrinter:FillRect( {nLin+1,nColB1+1,nLin+0010-1,nColB2-1} , oBrush)
				oPrinter:Say(nLin+7,0230,"Unidades Autorizadas",oCalib9N,,1)

				nLin := nLin+0010

				//8° quadrante
				aFilAut  := IIF(!Empty(U56->U56_FILAUT),StrTokArr(AllTrim(U56->U56_FILAUT),"/"),{})
				nCount   := 010

				oPrinter:Box(nLin,nColB1,nLin+(len(aFilAut)*nCount)+010,nColB2)

				nRecSM0 := SM0->(RecNo())
				dbSelectArea("SM0")
				SM0->(DbSetOrder(1))
				oPrinter:Say(nLin+nCount,nColT1,"Unidades:",oCalib9N,,0)
				For nX:=1 to len(aFilAut)
					If SM0->(DbSeek(cEmpAnt+aFilAut[nX]))
						if len(aNomeM0) >= 1
							cAux := ""
							For nY := 1 To len(aNomeM0)
								if !empty(cAux)
									cAux += " / "
								endif
								cAux += AllTrim(SM0->&(aNomeM0[nY]))
							next nY
							oPrinter:Say(nLin+nCount,nColC1,SubStr(cAux,1,50),oCalibr9,,0)
						else
							oPrinter:Say(nLin+nCount,nColC1,SubStr(AllTrim(SM0->M0_NOME) + " / " + AllTrim(SM0->M0_NOMECOM),1,50),oCalibr9,,0)
						endif
						
						oPrinter:Say(nLin+nCount,nColT2,"CNPJ:",oCalib9N,,0)
						oPrinter:Say(nLin+nCount,nColC2,Transform(SM0->M0_CGC,"@R 99.999.999/9999-99"),oCalibr9,,0)
						nCount += 010
					EndIf
				next nX
				SM0->(DbGoTo(nRecSM0))

				nLin := nLin+nCount
			EndIf

			If lSetp
				oPrinter:EndPage() //finaliza pagina
				//oPrinter:Print()
				oPrinter:Preview()
				EnvMail()
				If !Empty(cParc)// envia apenas a parcela informada nos parametros.
					Exit
				EndIf
			Else
				oPrinter:EndPage() //finaliza pagina
			EndIf

			U57->(dbskip())
		EndDo
	EndIf

	RestArea(aAreaU56)
	RestArea(aAreaU57)
	RestArea(aArea)
Return

//
// Envia as Requisições por parcela para o cliente e o motorista, caso estejam preenchidos nos respectivos cadastros.
//
Static function EnvMail()

	Local xHTM 		:= ""
	Local cDestino  := ""
	Local cAviso	:= ""
	Local cLocal	:= "\spool\"

	If !isBlind()
		CpyT2S( "C:\spool\"+cFilePrint+".pdf", "\spool", .F. )// Copia o arquivo para o servidor
	endif
	cAviso	:= "Requisição " + AllTrim(SM0->M0_NOME) + " - N. "+AllTrim(U56->(U56_FILIAL+U56_PREFIX+U56_CODIGO)+U57->U57_PARCEL)

	If !Empty(U57->U57_EMAIL)
		cDestino := AllTrim(U57->U57_EMAIL)
	EndIf

	cA1_EMAIL := Alltrim(Posicione("SA1",1,xFilial("SA1")+U56->U56_CODCLI+U56->U56_LOJA,"A1_EMAIL"))
	If !Empty(cA1_EMAIL) .and. !(cA1_EMAIL $ cDestino)
		If !Empty(cDestino)
			cDestino += ";"+AllTrim(cA1_EMAIL)
		Else
			cDestino := AllTrim(cA1_EMAIL)
		EndIf
	EndIf

	xHTM := '<HTML><BODY>'
	xHTM += '<hr>'
	xHTM += '<p  style="word-spacing: 0; line-height: 100%; margin-top: 0; margin-bottom: 0">'
	xHTM += '<b><font face="Verdana" SIZE=3>'+cAviso+' &nbsp; '+dtoc(date())+'&nbsp;&nbsp;&nbsp;'+time()+'</b></p>'
	xHTM += '<hr>'
	xHTM += '<br>'
	xHTM += '<b><font face="Verdana" SIZE=3> Prezado(a) '+U56->U56_NOME+'</b></p>'
	xHTM += '<br>'
	xHTM += 'Segue em anexo a seguinte requisição:<BR> <br>'
	xHTM += '<br>'
	xHTM += '<b><font face="Verdana" SIZE=3> Código de Barras:     	'+AllTrim(U56->(U56_FILIAL+U56_PREFIX+U56_CODIGO)+U57->U57_PARCEL)+'</b></p>'
	xHTM += '<br>'
	xHTM += '<b><font face="Verdana" SIZE=3> Requisitante:     	'+U56->U56_REQUIS+'</b></p>'
	xHTM += '<br>'
	cPlaca := iif(!empty(U57->U57_PLACA),TransForm(U57->U57_PLACA,"@!R NNN-9N99")+ " - " + RetField('DA3',1,xFilial("DA3")+U57->U57_PLACA,'DA3_DESC'),"")
	If !EMPTY(cPlaca)
		xHTM += '<b><font face="Verdana" SIZE=3> Placa: 		'+cPlaca+ '</b></p>'
		xHTM += '<br>'
	EndIf
	cCpfMot := iif(!empty(U57->U57_MOTORI),TransForm(U57->U57_MOTORI,"@R 999.999.999-99")+" - "+Posicione("DA4",3,xFilial("DA3")+U57->U57_MOTORI,"DA4_NOME"),"")
	If !EMPTY(cCpfMot)
		xHTM += '<b><font face="Verdana" SIZE=3> Motorista: '+cCpfMot+'</b></p>'
		xHTM += '<br>'
	EndIf
	xHTM += '<br>'
	xHTM += '<br>'
	xHTM += '<br>'
	xHTM += '<br>'
	xHTM += '<br>'
	xHTM += 'TOTVS - Este e-mail foi enviado automaticamente pelo sistema. Favor não responder.<BR> <br>'
	xHTM += '<br>'
	xHTM += '</BODY></HTML>'

	If !Empty(cDestino)
		oMail := LTpSendMail():New(Alltrim(cDestino), "Requisição " + AllTrim(SM0->M0_NOME) + " - N. "+AllTrim(U56->(U56_FILIAL+U56_PREFIX+U56_CODIGO)+U57->U57_PARCEL), xHTM)
		oMail:SetShedule(.T.)
		oMail:SetAttachment(cLocal+cFilePrint+".pdf")
		oMail:Send()
	Else
		If !IsBlind() //se nao for rotina automatica
			MsgStop("Não existe e-mail cadastrado para o cliente ou motorista!","ERRO")
		Else
			//Conout("TRETR010: Não existe e-mail cadastrado para o cliente ou motorista!")
		EndIf
	EndIf

	If !isBlind()
		FERASE("C:\spool\"+cFilePrint+".pdf") //Deletar Arquivo no remote
	endif
	FERASE(cLocal+cFilePrint+".pdf")  //Deletar Arquivo no Servidor

Return

//
// Quebra texto
//
Static Function QuebraTexto(_cString,_nCaracteres)

	Local aTexto      := {}
	Local cAux        := ""
	Local cString     := AllTrim(_cString)
	Local nX          := 1
	Local nY          := 1

	if _nCaracteres > Len(cString)
		aadd(aTexto,cString)
	else

		While nX <= Len(cString)
			cAux := SubStr(cString,nX,_nCaracteres)
			if Empty(cAux)
				nX += _nCaracteres
			else
				if SubStr(cAux,Len(cAux),1) == " " .OR. nX + _nCaracteres > Len(cString)
					aadd(aTexto,cAux)
					nX += _nCaracteres
				else
					For nY := Len(cAux) To 1 Step -1
						if SubStr(cAux,nY,1) == " "
							aadd(aTexto,SubStr(cAux,1,nY))
							nX += nY
							Exit
						endif
					Next nY
				endif
			endif
		EndDo
	endif

Return(aTexto)
